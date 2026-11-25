# Identity::Gateway

Identity's gateway provider for Ruby and Rails applications. Act as a man in the middle between backend services and Identity.

The provider resolves the resource behind a bearer token by asking Identity's `/me`, then trusts the token for `token_ttl` seconds: within that time a request costs one cache read and one `find_by`. The cache holds a SHA256 digest of the token and the resource id only, never the token. A token Identity revokes, or a permission it withdraws, stops working within `token_ttl`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'identity-gateway', git: 'git@github.com:wamland-team/identity-gateway.git', tag: 'v2.0.0'
```

Use Bundler to install the dependency:

    $ bundle

## Usage

Once you've configured it, you can use the `Identity::Gateway::Provider` class in order to act as your authentication mechanism.

```ruby
# app/controllers/api_controller.rb
module Api
  class ApiController < ApplicationController
    def authorize_access!
      @provider = Identity::Gateway::Provider.new(request)
      @provider.authorize!
    end
  end
end

# app/controllers/api/v1/posts_controller.rb
module Api
  module V1
    class PostsController < Api::ApiController
      before_action :authorize_access!, only: [:index]

      def index
        # Only authenticated users can access it.
      end
    end
  end
end
```

### Current subject

A subject is the instance associated to the model you specify using the `model` option when you configure the gem. Any instance of `Identity::Gateway::Provider` expose a public method name `current_resource` that allows you to retrieve the resource associated to a given access token.

```ruby
# app/controllers/api_controller.rb
module Api
  class ApiController < ApplicationController
    def authorize_access!
      @provider = Identity::Gateway::Provider.new(request)
      @provider.authorize!
    end

    def current_user
      @current_user ||= @provider.current_resource
    end
  end
end
```

### Model

The model answers two class methods:

* `find_by(id:)`: the resource remembered for a token, or nil;
* `from_oauth_provider(me_hash)`: the resource created or updated from Identity's `/me` body, responding to `id`.

### Errors

* `Identity::Gateway::Unauthorized`: no bearer token, or Identity refused it (any client error but 429). Answer 401.
* `Identity::Gateway::Unavailable`: Identity timed out, was unreachable, rate limited the call, answered a server error or a body that is no user. Answer 503, so that the client does not take an outage for a sign out.

```ruby
class ApplicationController < ActionController::API
  rescue_from Identity::Gateway::Unauthorized, with: :unauthorized_response
  rescue_from Identity::Gateway::Unavailable, with: :unavailable_response
end
```

### Fresh account

`refresh!` asks `/me` whatever the cache holds, and remembers the token again: for an endpoint that renders the account as Identity describes it now.

### Sign out

`revoke_access!` revokes the token on Identity, then forgets it. It raises `Unavailable` when Identity does not answer or fails: the token is then still valid, and still remembered.

### Before authorization

`Identity::Gateway::Provider.token_from(header)` reads the bearer token of an `Authorization` header by the provider's own rule, and `Identity::Gateway::Provider.cached_resource_id(token)` is the id remembered for it, nil if unknown: together they let a rate limiter tell whose the token is without asking Identity.

### Specs

`Identity::Gateway::Provider.remember(token, resource_id, nil)` remembers a token as if `/me` had just confirmed it, for `token_ttl`: an app's specs sign a user in without stubbing `/me`.

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

### cache

The store holding the confirmed tokens, an `ActiveSupport::Cache` store shared by every process. A cache failure is logged and taken for a miss.

```ruby
config.cache = Rails.cache
```

### token_ttl

Seconds a confirmed token is trusted, 120 by default, capped by the token's own lifetime. A value that is no non-negative integer raises at boot.

```ruby
config.token_ttl = ENV.fetch('IDENTITY_TOKEN_TTL_SECONDS', nil)
```

### timeout

Seconds to wait on Identity, 5 by default.

```ruby
config.timeout = 5
```

### logger

Logger told of cache failures.

```ruby
config.logger = Rails.logger
```

### version_header

This option allows you to define the `Accept` header use to determinate which version of Identity's API you which to use:

```ruby
config.version_header = 'application/vnd.wamland+json; version=1'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wamland-team/identity-gateway.
