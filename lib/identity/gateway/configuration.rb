# frozen_string_literal: true

module Identity
  module Gateway
    class Configuration
      # Seconds a token Identity confirmed is trusted without asking it again.
      DEFAULT_TOKEN_TTL = 120

      # Seconds to wait on Identity before taking it for unavailable.
      DEFAULT_TIMEOUT = 5

      # * <tt>model</tt> - Class, or its name, answering find_by(id:) and
      #   from_oauth_provider(me_hash).
      # * <tt>cache</tt> - ActiveSupport::Cache store (Rails.cache) holding
      #   the confirmed tokens.
      # * <tt>logger</tt> - Logger told of cache failures, or nil.
      attr_accessor :model, :provider_url, :identity_path, :version_header, :cache, :timeout, :logger
      attr_reader :token_ttl

      # Initialize a configuration.
      #
      # ==== Returns
      # * <tt>Identity::Gateway::Configuration</tt> - New instance.
      def initialize
        @model = 'User'
        @identity_path = '/me'
        @token_ttl = DEFAULT_TOKEN_TTL
        @timeout = DEFAULT_TIMEOUT
      end

      # Set how long a confirmed token is trusted: a revoked token or a
      # withdrawn permission keeps working that long at most.
      #
      # ==== Parameters
      # * <tt>value</tt> - Integer or base 10 String seconds; blank keeps the default.
      #
      # ==== Raises
      # * <tt>ArgumentError</tt> - Anything but a non-negative integer, so a
      #   mistyped environment value stops the boot instead of silently
      #   changing how long a revoked token keeps working.
      def token_ttl=(value)
        @token_ttl = value.nil? || value.to_s.strip.empty? ? DEFAULT_TOKEN_TTL : parse_seconds(value)
      end

      # The model class.
      #
      # ==== Returns
      # * <tt>Object</tt> - The model, resolved from its name when given one.
      def model_class
        model.is_a?(String) ? Object.const_get(model) : model
      end

      private

      def parse_seconds(value)
        seconds = value.is_a?(String) ? Integer(value, 10) : Integer(value)
        raise ArgumentError, "token_ttl must not be negative: #{value}" if seconds.negative?

        seconds
      end
    end
  end
end
