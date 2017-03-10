require 'spec_helper'

RSpec.describe Identity::Gateway do
  class User
  end

  describe 'configure block' do
    before(:each) do
      Identity::Gateway.configure do |config|
        config.provider_url = 'https://identity.domain.com'
        config.model = User
      end
    end

    it 'allows to define defaults' do
      expect(Identity::Gateway.configuration.provider_url).to eq 'https://identity.domain.com'
      expect(Identity::Gateway.configuration.model).to eq User
    end

    after(:each) do
      Identity::Gateway.reset
    end
  end
end
