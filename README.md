# Grape::Batch

Rack middleware which extends Grape::API to support request batching.

## Installation

Add this line to your application's Gemfile:

    gem 'grape-batch'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape-batch

## Usage
### General considerations
This middleware is intended to be used with JSON Grape::API only.

### Rails apps
1. Create an initializer 'config/initializers/grape-batch.rb'
2. Add the middleware to the stack
```ruby
# grape-batch.rb
Rails.application.configure do
 config.middleware.insert_before Rack::Sendfile, Grape::Batch::Base
end
```

### Sinatra and other Rack apps
```ruby
# config.ru
require 'grape/batch'
use Grape::Batch::Base
```

### Settings
You can customize the middleware with a hash.

| Argument | Type | Default | Description
| :---: | :---: | :---: | :---:
| :limit | integer | 10 | Maximum number of batched requests allowed by the middleware
| :path | string | /batch | Route on which the middleware is mounted on
| :formatter | class | Grape::Batch::Response | The response formatter to use

#### Response formatter
#####Default format (success)
```ruby
{success: RESOURCE_RESPONSE}
```

#####Default format (failure)
```ruby
{code: HTTP_STATUS_CODE, error: ERROR_MESSAGE}
```

Can be inherited easily.
```ruby
class MyFormatter < Grape::Batch::Response
  def self.format(status, headers, body)
    # My awesome formatting
  end
end
```

### Input format
POST http request on the default URL with a similar body:
```ruby
{
  requests: 
    [
      {
        method: 'GET', 
        path: '/api/v1/users'
      },
      {
        method: 'POST', 
        path: '/api/v1/login',
        body: { token: 'nrg55xwrd45' }
      }
    ]
}
```

'body' is optional.

## Contributing

1. Fork it ( https://github.com/c4mprod/grape-batch/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request