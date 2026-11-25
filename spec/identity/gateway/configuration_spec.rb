# frozen_string_literal: true

module Identity
  module Gateway
    RSpec.describe Configuration do
      subject(:configuration) { described_class.new }

      it 'has defaults' do
        expect(configuration).to have_attributes(model: 'User', identity_path: '/me', provider_url: nil, version_header: nil,
                                                 cache: nil, token_ttl: 120, timeout: 5, logger: nil)
      end

      describe '#token_ttl=' do
        it 'takes seconds as an integer or a base 10 string' do
          configuration.token_ttl = '300'
          expect(configuration.token_ttl).to eq 300

          configuration.token_ttl = 60
          expect(configuration.token_ttl).to eq 60
        end

        it 'keeps the default for a blank value' do
          configuration.token_ttl = ''

          expect(configuration.token_ttl).to eq 120
        end

        it 'refuses anything but a non-negative integer' do
          expect { configuration.token_ttl = '2m' }.to raise_error(ArgumentError)
          expect { configuration.token_ttl = -1 }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
