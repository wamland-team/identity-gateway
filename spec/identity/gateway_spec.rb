# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Identity::Gateway do
  describe 'configure block' do
    before(:each) do
      Identity::Gateway.configure do |config|
        config.model          = 'Admin'
        config.provider_url   = 'https://identity.domain.com'
        config.identity_path  = '/my-account'
        config.version_header = 'application/vnd.company+json; version=1'
      end
    end

    it 'allows to define or override defaults' do
      configuration = Identity::Gateway.configuration

      expect(configuration.model).to eq 'Admin'
      expect(configuration.provider_url).to eq 'https://identity.domain.com'
      expect(configuration.identity_path).to eq '/my-account'
      expect(configuration.version_header).to eq 'application/vnd.company+json; version=1'
    end

    after(:each) do
      Identity::Gateway.reset
    end
  end
end
