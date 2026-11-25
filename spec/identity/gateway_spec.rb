# frozen_string_literal: true

RSpec.describe Identity::Gateway do
  describe '.configure' do
    it 'overrides the defaults' do
      described_class.configure do |config|
        config.model          = 'Admin'
        config.provider_url   = 'https://identity.domain.com'
        config.identity_path  = '/my-account'
        config.version_header = 'application/vnd.company+json; version=1'
      end

      expect(described_class.configuration).to have_attributes(model: 'Admin', provider_url: 'https://identity.domain.com',
                                                               identity_path: '/my-account',
                                                               version_header: 'application/vnd.company+json; version=1')
    end
  end
end
