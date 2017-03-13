# Identity::Gateway

Identity's gateway provider for Ruby and Rails applications. Act as a man in the middle between backend services and Identity.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'identity-gateway', '~> 1.0'
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

### Rescuing a denied Authorization in Rails

Identity::Gateway raises a `Identity::Gateway::Unauthorized` error you can
[rescue_from](http://guides.rubyonrails.org/action_controller_overview.html#rescue-from)
in your `ApplicationController`. You can customize the `unauthorized_response`
method in every controller.

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  rescue_from Identity::Gateway::Unauthorized, with: :unauthorized_response

  private

  def unauthorized_response
    render json: { message: 'You need to sign in before continuing.' }, status: :unauthorized
  end
end
```

Alternatively, you can globally handle Identity::Gateway::Unauthorized's by having rails handle them as a 403 error and serving a 403 error page. Add the following to application.rb:

```ruby
config.action_dispatch.rescue_responses['Identity::Gateway::Unauthorized'] = :forbidden
```

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
