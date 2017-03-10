require 'identity/gateway/version'
require 'identity/gateway/configuration'

module Identity
  module Gateway
    class << self
      attr_writer :configuration
    end

    # Access module configuration.
    #
    # ==== Returns
    # * <tt>Identity::Gateway::Configuration</tt> - instance
    def self.configuration
      @configuration ||= Configuration.new
    end

    # Reset configuration to defaults.
    #
    # ==== Returns
    # * <tt>Identity::Gateway::Configuration</tt> - instance
    def self.reset
      @configuration = Configuration.new
    end

    # Configure block.
    #
    # ==== Returns
    # * <tt>void</tt>
    def self.configure
      yield(configuration)
    end
  end
end
