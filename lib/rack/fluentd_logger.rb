# frozen_string_literal: true

require 'English'
require 'fluent-logger'
require 'concurrent'
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
        preprocessor: ->(d) { d },
        max_body_non_json: 256
      )
        @logger = Fluent::Logger::FluentLogger.new(name, host: host, port: port)

        @json_parser = json_parser
        @preprocessor = preprocessor
        @max_body_non_json = max_body_non_json
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
      return format_response_error(response) if response.is_a?(Exception)

      code, headers, body = response

      body = body.body if body.respond_to?(:body)
      body = [body] if body.is_a? String

      body = if headers['Content-Type'] && headers['Content-Type'].include? 'json'
               body.map { |s| self.class.json_parser&.call(s) }
             else
               body[0..@max_body_non_json]
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
