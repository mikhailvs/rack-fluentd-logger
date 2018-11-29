# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rack/fluentd-logger-version'

Gem::Specification.new do |s|
  s.name = 'rack-fluentd-logger'
  s.version = Rack::FluentdLogger::VERSION
  s.authors = ['Mikhail Slyusarev']
  s.email = ['slyusarevmikhail@gmail.com']
  s.summary = 'Rack middleware for logging traffic to fluentd.'
  s.homepage = 'https://github.com/mikhailvs/rack-fluentd-logger'
  s.files = ['lib/*.rb']
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'

  s.add_runtime_dependency 'concurrent-ruby'
  s.add_runtime_dependency 'fluent-logger', '~> 0.7.2'
end
