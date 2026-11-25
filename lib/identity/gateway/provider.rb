# frozen_string_literal: true

require 'digest'
require 'httparty'
require 'json'

module Identity
  module Gateway
    # Identity refused the token: it answered a client error.
    class Unauthorized < StandardError; end

    # Identity could not tell whether the token is valid: it timed out, was
    # unreachable, rate limited the call, answered a server error or a body
    # that is no user. Distinct from Unauthorized so that an outage is not
    # taken for a revocation, and the client is not signed out.
    class Unavailable < StandardError; end

    # Resolves the resource behind a bearer token.
    #
    # Identity revokes a token at sign out and whenever the user's rights
    # change, without telling the API. A token is therefore trusted only for
    # token_ttl after /me last confirmed it, then confirmed again: a revoked
    # token or a withdrawn permission stops working within that TTL rather
    # than at the token's nominal expiry.
    #
    # The cache maps a SHA256 digest of the token to the resource id, so the
    # token itself is never stored. A cache failure is a miss: every request
    # then goes to /me, slower but never trusting an unconfirmed token.
    class Provider
      include HTTParty

      BEARER = /\ABearer (\S+)\z/

      # Transport failures meaning Identity did not answer: timeouts, DNS,
      # every Errno::*, a malformed HTTP answer, TLS, a dropped stream and
      # HTTParty's own errors.
      UNREACHABLE = [
        Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, SocketError, SystemCallError,
        Net::HTTPBadResponse, OpenSSL::SSL::SSLError, IOError, HTTParty::Error
      ].freeze

      class << self
        # Bearer token of an Authorization header, the one rule every caller
        # reads it by.
        #
        # ==== Returns
        # * <tt>String|nil</tt> - Token, nil without a single well-formed bearer.
        def token_from(header)
          header.to_s[BEARER, 1]
        end

        # Cache key of a token.
        #
        # ==== Returns
        # * <tt>String</tt> - Key holding the token's SHA256 digest only.
        def cache_key(token)
          "identity/token/#{Digest::SHA256.hexdigest(token)}"
        end

        # Id of the resource Identity confirmed the token for, within the TTL.
        # Lets a caller that runs before authorization (a rate limiter) tell
        # whose the token is without asking Identity.
        #
        # ==== Returns
        # * <tt>Object|nil</tt> - Resource id; nil if unknown, blank or the cache failed.
        def cached_resource_id(token)
          return if token.nil? || token.empty?

          with_cache { |cache| cache.read(cache_key(token)) }
        end

        # Remember that Identity confirmed a token, for the TTL capped by the
        # token's own lifetime when Identity tells it; nothing for a token
        # already expired. Public so that an app's specs can sign a user in
        # without stubbing /me.
        def remember(token, resource_id, expires_in)
          ttl = [settings.token_ttl, expires_in&.to_i].compact.min
          return unless ttl.positive?

          with_cache { |cache| cache.write(cache_key(token), resource_id, expires_in: ttl) }
        end

        # Forget a token, once Identity revoked it.
        def forget(token)
          with_cache { |cache| cache.delete(cache_key(token)) }
        end

        # Gateway configuration, read on every call so that a reconfiguration
        # (specs) takes effect.
        def settings
          Identity::Gateway.configuration
        end

        private

        # Run a cache call, a failure being only a lost shortcut: nil.
        def with_cache
          yield settings.cache
        rescue StandardError => e
          settings.logger&.warn("Identity token cache failed: #{e.class}")
          nil
        end
      end

      # Class initializer.
      #
      # ==== Parameters
      # * <tt>request</tt> - Current request.
      def initialize(request)
        @settings = self.class.settings
        @request  = request
        @resource = nil
      end

      # The resource the token belongs to, once authorized.
      #
      # ==== Returns
      # * <tt>Object</tt> - Instance or nil.
      def current_resource
        @resource
      end

      # Resolve the token's resource, from the cache within the TTL, from
      # Identity otherwise.
      #
      # ==== Returns
      # * <tt>Object</tt> - Resolved resource.
      #
      # ==== Raises
      # * <tt>Unauthorized</tt> - No bearer token, or Identity refuses it.
      # * <tt>Unavailable</tt>  - Identity did not answer usably.
      def authorize!
        raise Unauthorized unless request_token

        resource_id = self.class.cached_resource_id(request_token)
        @resource = (cached_resource(resource_id) if resource_id) || authorize_from_provider
      end

      # Ask Identity again, whatever the cache holds: for an endpoint that
      # must render the account as Identity describes it now.
      #
      # ==== Returns
      # * <tt>Object</tt> - Resource synced from /me.
      #
      # ==== Raises
      # * <tt>Unauthorized</tt> - No bearer token, or Identity refuses it.
      # * <tt>Unavailable</tt>  - Identity did not answer usably.
      def refresh!
        raise Unauthorized unless request_token

        authorize_from_provider
      end

      # Revoke the token on Identity, then forget it. Forgotten only once
      # Identity revoked it: a token still valid there would otherwise be
      # confirmed and remembered again on the next request, the sign out
      # reported done when it is not.
      #
      # ==== Returns
      # * <tt>HTTParty::Response</tt> - Identity's answer.
      #
      # ==== Raises
      # * <tt>Unauthorized</tt> - No bearer token.
      # * <tt>Unavailable</tt>  - Identity did not answer or failed.
      def revoke_access!
        raise Unauthorized unless request_token

        response = call_identity(:post, '/oauth/revoke', body: { token: request_token }.to_json)
        raise Unavailable, "Identity answered #{response.code}" unless response.success?

        self.class.forget(request_token)
        response
      end

      protected

      # Resource remembered for the token, read by primary key: `id` answers
      # the primary key's value, while find_by(id:) reads an `id` column a
      # model keyed otherwise may keep, which would hand the token to the
      # record whose `id` column holds that value.
      def cached_resource(resource_id)
        model = @settings.model_class
        model.find_by(model.primary_key => resource_id)
      end

      # Ask Identity who owns the token, sync the resource and remember it.
      def authorize_from_provider
        hash = confirmed_identity
        @resource = @settings.model_class.from_oauth_provider(hash)
        self.class.remember(request_token, @resource.id, hash.dig('access_token', 'expires_in_seconds'))
        @resource
      end

      # Identity's /me body, once it confirmed the token.
      def confirmed_identity
        response = call_identity(:get, @settings.identity_path)
        raise Unauthorized if (400..499).cover?(response.code) && response.code != 429
        raise Unavailable, "Identity answered #{response.code}" unless response.success?

        body = parsed_body(response)
        raise Unavailable, 'Identity answered no user' unless body.is_a?(Hash) && body['id']

        body
      end

      # Body of Identity's answer, a malformed JSON being no reason for a 500.
      def parsed_body(response)
        response.parsed_response
      rescue JSON::ParserError => e
        raise Unavailable, e.class.name
      end

      # Call Identity, bounded in time.
      def call_identity(verb, path, **)
        self.class.public_send(verb, "#{@settings.provider_url}#{path}", headers: api_headers, timeout: @settings.timeout, **)
      rescue *UNREACHABLE => e
        raise Unavailable, e.class.name
      end

      # Bearer token of the Authorization header.
      #
      # ==== Returns
      # * <tt>String|nil</tt> - Token, nil without a well-formed bearer.
      def request_token
        self.class.token_from(@request.headers['Authorization'])
      end

      # Required headers.
      def api_headers
        {
          'Content-Type'  => 'application/json',
          'Accept'        => @settings.version_header.to_s,
          'Authorization' => "Bearer #{request_token}"
        }
      end
    end
  end
end
