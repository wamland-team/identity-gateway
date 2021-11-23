require 'httparty'

module Identity
  module Gateway
    class Unauthorized < StandardError; end
    class Provider
      include HTTParty

      # Class initializer.
      #
      # ==== Parameters
      # * <tt>request</tt> - Current request.
      #
      # ==== Returns
      # Assigns arguments to instance variables.
      def initialize(request)
        @settings = Identity::Gateway.configuration
        @request  = request
        @response = {}
        @subject  = nil
        @model    = Object.const_get(@settings.model)
      end

      # Get token resource owner.
      #
      # ==== Returns
      # * <tt>Object</tt> - HTTParty response or identity error.
      def authorize!
        token = request_token
        @subject = @model.find_by(token: token)
        return unless (@subject && @subject.token_has_expired?) || @subject.nil?
        authorize_from_provider
      end

      # The current instance object associated to
      # the model define in the configuration.
      #
      # ==== Returns
      # * <tt>Object</tt> - instance or nil.
      def current_resource
        @subject
      end

      # Revoke access token.
      #
      # ==== Returns
      # * <tt>HTTParty::Response</tt>.
      def revoke_access!
        self.class.post(
          "#{@settings.provider_url}/oauth/revoke",
          body: { token: request_token }.to_json,
          headers: api_headers
        )
      end

      protected

      # Try to authorize token against provider.
      #
      # ==== Returns
      # * <tt>ActiveRecord|Error</tt> - User object, error otherwise.
      def authorize_from_provider
        @response = self.class.get(
          @settings.provider_url + @settings.identity_path,
          headers: api_headers
        )

        raise Unauthorized if invalid_response?(@response)
        @subject = @model.from_oauth_provider(@response.parsed_response)
      end

      # Get oauth token from headers.
      #
      # ==== Returns
      # * <tt>String</tt> - token.
      def request_token
        (@request.headers['Authorization'] || '').gsub('Bearer ', '')
      end

      # Required headers.
      #
      # ==== Returns
      # * <tt>Hash</tt> - Hash of headers.
      def api_headers
        {
          'Content-Type'  => 'application/json',
          'Accept'        => @settings.version_header || '',
          'Authorization' => @request.headers['Authorization'] || ''
        }
      end

      # Invalid Response.
      #
      # ==== Returns
      # * <tt>Boolean</tt> - True if is an invalid response.
      def invalid_response?(response)
        parsed_response = response.parsed_response
        return true if response.code == 401 || parsed_response.nil? || parsed_response['id'].nil?

        false
      end
    end
  end
end
