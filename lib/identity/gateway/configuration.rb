module Identity
  module Gateway
    class Configuration
      attr_accessor :model, :provider_url, :identity_path, :version_header

      # Initialize a configuration.
      #
      # ==== Returns
      # * <tt>Identity::Gateway::Configuration</tt> - New instance.
      def initialize
        @model = 'User'
        @identity_path = '/me'
      end
    end
  end
end
