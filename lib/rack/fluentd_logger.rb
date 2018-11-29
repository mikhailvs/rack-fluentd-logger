# frozen_string_literal: true

require 'fluent-logger'
require 'concurrent-ruby'
require 'json'

module Rack
  class FluentdLogger
    class << self
      attr_reader :logger, :json_parser

      def configure(
        name: ENV['FLUENTD_NAME'],
        host: ENV['FLUENTD_HOST'],
        port: (ENV['FLUENTD_PORT'] || 24_224).to_i,
        json_parser: ->(str) { JSON.parse(str) },
        preprocesser: ->(d) { d }
      )
        @logger = Fluent::Logger::FluentLogger.new(name, host: host, port: port)

        @json_parser = json_parser
        @preprocesser = preprocesser
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

      log_request(env, response, Time.now - start)

      response
    end

    private

    def log_request(env, response, response_time)
      @executer.post do
        record = {
          env: drop_objects(env),
          timestamp: Time.now,
          response_time: response_time,
          **format_response(response)
        }

        self.class.logger
            .post('rack-traffic-log', self.class.preprocesser&.call(record))
      end
    end

    def format_response(response)
      code, headers, body = response

      if headers['Content-Type'] == 'application/json'
        body = self.class.json_parser&.call(body)
      end

      { code: code, body: body, headers: headers }
    end

    def drop_objects(obj)
      return unless [Hash, Number, Array, String].include?(obj.class)

      case obj
      when Hash
        obj.reduce { |m, (k, v)| m.merge!(k => drop_objects(v)) }.compact
      when Array
        obj.reduce { |m, v| m + drop_objects(v) }.compact
      else
        obj
      end
    end
  end
end
