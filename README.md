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

You can configure Identity::Gateway by creating an initializer `config/initializers/identity_gateway.rb` and passing it a `configure` block:

```ruby
Identity::Gateway.configure do |config|
  # Define options here
end
```

## Options

### model

This option allows you to define the name of the model you wish to associate. For example, if you handle cache for users with a User model, then it could looks like:

```ruby
config.model = 'User'
```

### provider_url

This option allows you to define the url to your Identity server:

```ruby
config.provider_url = 'https://identity.domain.com'
```

### identity_path

This option allows you to define the path on Identity that return the information about the current user. Generally, this path will be `/me`:

```ruby
config.identity_path = '/me'
```

### version_header

This option allows you to define the `Accept` header use to determinate which version of Identity's API you which to use:

```ruby
config.version_header = 'application/vnd.wamland+json; version=1'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wamland-team/identity-gateway.
