module Identity
  module Gateway
    class Configuration
      attr_accessor :provider_url, :model, :segment_path

      # Initialize a configuration.
      #
      # ==== Returns
      # * <tt>Identity::Gateway::Configuration</tt> - New instance.
      def initialize
        @segment_path = '/me'
      end
    end
  end
end
