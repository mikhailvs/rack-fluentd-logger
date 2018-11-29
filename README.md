# Rack Fluentd Logger

## Install

Gemfile:
```ruby
gem 'serializer', github: 'mikhailvs/simple-serializer'
```

## Usage

config.ru
```ruby

require 'rack-fluentd-logger'

Rack::FluentdLogger.configure(
  name: 'your-app-log-name',
  host: 'your-fluentd-host',
  port: 24224
)

use Rack::FluentdLogger

run YourApplication

```

## Configuration Options
| name | default | description |
| ---- | ------- | ----------- |
| name | `ENV['FLUENTD_NAME']` | application name to use for fluentd logs |
| host | `ENV['FLUENTD_HOST']` | fluentd server hostname/ip |
| port | `ENV['FLUENTD_PORT'] || 24_224` | fluentd server port |
| json_parser | `->(str) { JSON.parse(str) }` | used to parse response bodies if they are `application/json` |
| preprocessor | `->(s) { s }` | callback for any additional processing/scrubbing of data before sending it off |

## Event Data
Events sent to fluentd have the following structure
```ruby
{
  env: {
    # everything from the rack env that's an array/hash/string/number
  },
  timestamp: Time.now, # current time when the log event is recorded
  response_time: 0.012, # length of time in seconds for response from rack
  code: 200, # http response code from rack app
  body: [], # body from rack app (when the content_type is json, it's parsed)
  headers: {} # http headers from the rack app
}
```
