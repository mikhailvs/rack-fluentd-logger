# frozen_string_literal: true

require 'English'
require 'fluent-logger'
require 'concurrent-ruby'
require 'json'

module Rack
  class FluentdLogger
    class << self
      attr_reader :logger, :json_parser, :preprocessor

      def configure(
        name: ENV['FLUENTD_NAME'],
        host: ENV['FLUENTD_HOST'],
        port: (ENV['FLUENTD_PORT'] || 24_224).to_i,
        json_parser: ->(str) { JSON.parse(str) },
        preprocessor: ->(d) { d }
      )
        @logger = Fluent::Logger::FluentLogger.new(name, host: host, port: port)

        @json_parser = json_parser
        @preprocessor = preprocessor
      end
    end

    def initialize(app)
      @app = app
      @executer = Concurrent::SingleThreadExecutor.new

      self.class.configure if self.class.logger.nil?
    end

    def call(env)
      start = Time.now
      response = @app.call(env)
    ensure
      log_request(env, response || $ERROR_INFO, Time.now - start)
    end

    private

    def log_request(env, response, response_time)
      @executer.post do
        record = self.class.preprocessor&.call(
          env: drop_objects(env),
          timestamp: Time.now,
          response_time: response_time,
          **format_response(response)
        )

        self.class.logger.post('rack-traffic-log', record)
      end
    end

    def format_response(response)
      return format_response_error(response) if response.is_a?(Error)

      code, headers, body = response

      if headers['Content-Type'] == 'application/json'
        body = body.map { |s| self.class.json_parser&.call(s) }
      end

      { code: code, body: body, headers: headers }
    end

    def format_response_error(error)
      {
        class: error.class,
        message: error.message,
        backtrace: error.backtrace
      }
    end

    def drop_objects(obj)
      allowed = [Hash, Array, String, Numeric]

      return unless allowed.reduce(false) { |m, c| m || obj.is_a?(c) }

      case obj
      when Hash
        obj.reduce({}) { |m, (k, v)| m.merge!(k => drop_objects(v)) }.compact
      when Array
        obj.map { |v| drop_objects(v) }.compact
      else
        obj
      end
    end
  end
end
