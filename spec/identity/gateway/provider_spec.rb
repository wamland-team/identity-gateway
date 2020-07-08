require 'spec_helper'

class User; end

module Identity
  module Gateway
    RSpec.describe Provider do
      class MockRequest
        attr_accessor :headers
        def initialize(headers = {})
          @headers = headers
        end
      end

      class MockResponse
        attr_accessor :code, :parsed_response
        def initialize(code = nil, parsed_response = {})
          @code = code
          @parsed_response = parsed_response
        end
      end

      let(:user)    { User.new }
      let(:request) { MockRequest.new('Authorization' => 'Bearer 123456789') }

      before(:each) do
        Identity::Gateway.configure do |config|
          config.model          = 'User'
          config.identity_path  = '/me'
          config.provider_url   = 'https://identity.domain.com'
          config.version_header = 'application/vnd.wamland+json; version=1;'
        end
      end

      after(:each) do
        Identity::Gateway.reset
      end

      describe '.current_resource' do
        context 'not authenticated' do
          it 'returns nil' do
            identity = Provider.new(request)
            expect(identity.current_resource).to be_nil
          end
        end

        context 'authenticated' do
          before(:each) do
            allow(User).to receive(:find_by).and_return(user)
            allow_any_instance_of(User).to receive(:token_has_expired?).and_return(false)
          end

          it 'returns user instance' do
            identity = Provider.new(request)
            identity.authorize!
            expect(identity.current_resource).to eq user
          end
        end
      end

      describe '.authorize!' do
        before(:each) do
          allow_any_instance_of(Provider).to receive(:authorize_from_provider)
        end

        context 'token found' do
          before(:each) do
            allow(User).to receive(:find_by).and_return(user)
          end

          context 'is expired' do
            before(:each) do
              allow_any_instance_of(User).to receive(:token_has_expired?).and_return(true)
            end

            it 'calls .authorize_from_provider' do
              expect_any_instance_of(Provider).to receive(:authorize_from_provider)
              identity = Provider.new(request)
              identity.authorize!
            end
          end

          context 'is not expired' do
            before(:each) do
              allow_any_instance_of(User).to receive(:token_has_expired?).and_return(false)
            end

            it 'does not call .authorize_from_provider' do
              expect_any_instance_of(Provider).not_to receive(:authorize_from_provider)
              identity = Provider.new(request)
              identity.authorize!
            end
          end
        end

        context 'token not found' do
          before(:each) do
            allow(User).to receive(:find_by).and_return(nil)
          end

          it 'calls .authorize_from_provider' do
            expect_any_instance_of(Provider).to receive(:authorize_from_provider)
            identity = Provider.new(request)
            identity.authorize!
          end
        end
      end

      describe '.authorize_from_provider' do
        context 'response is unauthorized' do
          before(:each) do
            allow(Provider).to receive(:get).and_return(response)
          end

          context 'when receive a 401 code' do
            let(:response) { MockResponse.new(401) }

            it 'raises an error' do
              identity = Provider.new(request)
              expect { identity.send(:authorize_from_provider) }.to raise_error(Unauthorized)
            end
          end

          context 'when the parsed_response is nil' do
            let(:response) { MockResponse.new(200, nil) }

            it 'raises an error' do
              identity = Provider.new(request)
              expect { identity.send(:authorize_from_provider) }.to raise_error(Unauthorized)
            end
          end
        end

        context 'has response' do
          let(:response) do
            MockResponse.new(200, 'id' => 10, 'token' => 'a1d8745b59')
          end

          before(:each) do
            allow(User).to receive(:from_oauth_provider)
            allow(Provider).to receive(:get).and_return(response)
          end

          it 'calls User.from_oauth_provider' do
            expect(User).to receive(:from_oauth_provider).with(response.parsed_response)

            identity = Provider.new(request)
            identity.send(:authorize_from_provider)
          end
        end
      end

      describe '.request_token' do
        it 'extracts token from headers' do
          identity = Provider.new(request)
          expect(identity.send(:request_token)).to eq '123456789'
        end
      end

      describe '.api_headers' do
        it 'returns a hash with required headers' do
          expectation = {
            'Content-Type'  => 'application/json',
            'Accept'        => 'application/vnd.wamland+json; version=1;',
            'Authorization' => 'Bearer 123456789'
          }
          identity = Provider.new(request)
          expect(identity.send(:api_headers)).to eq expectation
        end
      end
    end
  end
end
