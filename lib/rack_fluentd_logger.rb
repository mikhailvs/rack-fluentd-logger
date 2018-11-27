# frozen_string_literal: true

require 'fluentd-logger'
require 'concurrent-ruby'

class RackFluentdLogger
  VERSION = '0.1.0'
  JSON_PARSER = ->(str) { JSON.parse(str) }

  class << self
    attr_reader :logger, :json_parser

    def configure(name: nil, host: nil, port: nil, json_parser: JSON_PARSER)
      @logger = Fluent::Logger::FluentLogger.new(
        name || env.name,
        host: host || env.host,
        port: port || env.port
      )

      @json_parser = json_parser
    end

    def env
      OpenStruct.new(
        name: ENV['FLUENTD_NAME'],
        host: ENV['FLUENTD_HOST'],
        port: (ENV['FLUENTD_PORT'] || 24_224).to_i
      )
    end
  end

  def initialize(app)
    @app = app
    @executer = Concurrent::SingleThreadExecutor.new

    self.class.configure if self.class.logger.nil?
  end

  def call(env)
    response = @app.call(env)

    log_request(env, response)

    response
  end

  private

  def log_request(env, response)
    @executer.post do
      self.class.logger.post(
        'rack-traffic-log',
        env: env,
        **format_response(response)
      )
    end
  end

  def format_response(response)
    code, body, headers = response

    if headers['Content-Type'] == 'application/json'
      body = self.class.json_parser.call(body)
    end

    { code: code, body: body, headers: headers }
  end
end
