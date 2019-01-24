# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rack/fluentd_logger_version'

Gem::Specification.new do |s|
  s.name = 'rack-fluentd-logger'
  s.version = Rack::FluentdLogger::VERSION
  s.authors = ['Mikhail Slyusarev']
  s.email = ['slyusarevmikhail@gmail.com']
  s.summary = 'Rack middleware for logging traffic to fluentd.'
  s.homepage = 'https://github.com/mikhailvs/rack-fluentd-logger'
  s.files = [
    'lib/rack/fluentd-logger.rb',
    'lib/rack/fluentd_logger.rb',
    'lib/rack/fluentd_logger_version.rb'
  ]
  s.require_paths = ['lib']
  s.license = 'MIT'

  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rubocop', '~> 0.60'

  s.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  s.add_runtime_dependency 'fluent-logger', '~> 0.7'
end
