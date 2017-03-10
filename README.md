# Identity::Gateway

Identity's gateway provider for Ruby and Rails applications. Act as a man in the middle between backend services and Identity.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'identity-gateway', '~> 1.0'
```

Use Bundler to install the dependency:

    $ bundle

## Configuration

You can configure Identity::Gateway by creating an initializer `config/initializers/identity_gateway.rb` which allow you to define 3 options.

```ruby
Identity::Gateway.configure do |config|
  config.provider_url = 'https://identity.domain.com' # required
  config.model        = User  # required
  config.segment_path = '/me' # optional
end
```

| Option name    | Description                                                 | Required ? |
|----------------|-------------------------------------------------------------|---------|
| `provider_url` | Identity url                                                | `true`  |
| `model`        | The model responsible for caching user data                 | `true`  |
| `segment_path` | Path on Identity to get current user info. `/me` by default | `false` |

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wamland-team/identity-gateway.
