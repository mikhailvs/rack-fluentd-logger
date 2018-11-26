# frozen_string_literal: true

class RackFluentdLogger
  VERSION = '0.1.0'

  class << self
    attr_reader :logger, :extra

    def configure(name: nil, host: nil, port: nil, extra: nil)
      @logger = Fluent::Logger::FluentLogger.new(
        name || ENV['FLUENTD_NAME'],
        host: host || ENV['FLUENTD_HOST'],
        port: port || ENV['FLUENTD_PORT']
      )

      @extra = extra
    end
  end

  def initialize(app)
    @app = app

    if self.class.logger.nil?
      self.class.configure
    end
  end

  def call(env)
    response = @app.call(env)

    log_request(env, response)

    response
  end

  private

  def log_request(env, response)
    self.class.logger.post(
      'rack-traffic-log',
      env: env,
      response: response,
      extra: self.class.extra&.call
    )
  end
end
