# frozen_string_literal: true

module Identity
  module Gateway
    RSpec.describe Provider do
      let(:me_url) { 'https://identity.test/me' }
      let(:token) { 'token-1' }
      let(:users) { FakeUsers.new }
      let(:cache) { FakeCache.new }
      let(:logger) { instance_double(Logger, warn: nil) }
      let(:me_body) { { 'id' => 42, 'access_token' => { 'token' => token, 'expires_in_seconds' => 3600 } } }

      before do
        Identity::Gateway.configure do |config|
          config.model          = users
          config.provider_url   = 'https://identity.test'
          config.version_header = 'application/vnd.wamland+json; version=1'
          config.cache          = cache
          config.logger         = logger
        end
      end

      def provider(authorization = "Bearer #{token}")
        described_class.new(FakeRequest.new(authorization ? { 'Authorization' => authorization } : {}))
      end

      def stub_me(status: 200, body: me_body.to_json, content_type: 'application/json')
        stub_request(:get, me_url).to_return(status: status, body: body, headers: { 'Content-Type' => content_type })
      end

      def authorize(authorization = "Bearer #{token}")
        identity = provider(authorization)
        identity.authorize!
        identity
      end

      describe '#authorize!' do
        context 'with a token Identity confirms' do
          before { stub_me }

          it 'syncs the resource from /me and makes it current' do
            identity = authorize

            expect(identity.current_resource).to eq FakeUser.new(42)
            expect(users.synced).to eq [me_body]
          end

          it 'asks /me with the token and the configured version header' do
            authorize

            expect(WebMock).to have_requested(:get, me_url)
              .with(headers: { 'Authorization' => "Bearer #{token}", 'Accept' => 'application/vnd.wamland+json; version=1' })
          end

          it 'remembers the resource under a digest of the token, never the token itself' do
            authorize

            expect(cache.entries).to eq(described_class.cache_key(token) => 42)
            expect(cache.entries.keys.join).not_to include(token)
          end

          it 'remembers it for the configured TTL' do
            authorize

            expect(cache.ttls.values).to eq [120]
          end

          it 'remembers it no longer than the token lives' do
            me_body['access_token']['expires_in_seconds'] = 30
            stub_me

            authorize

            expect(cache.ttls.values).to eq [30]
          end
        end

        context 'with a token remembered within the TTL' do
          before do
            stub_me
            authorize
          end

          it 'skips /me' do
            identity = authorize

            expect(identity.current_resource).to eq FakeUser.new(42)
            expect(WebMock).to have_requested(:get, me_url).once
          end
        end

        context 'with a remembered token whose resource is gone' do
          it 'asks /me again' do
            cache.write(described_class.cache_key(token), 7, expires_in: 120)
            stub_me

            expect(authorize.current_resource).to eq FakeUser.new(42)
          end
        end

        context 'with a token already expired' do
          it 'remembers nothing' do
            me_body['access_token']['expires_in_seconds'] = 0
            stub_me

            authorize

            expect(cache.entries).to be_empty
          end
        end

        context 'without a bearer token' do
          it 'refuses it without asking /me' do
            [nil, '', 'Bearer ', "Basic #{token}", "xBearer #{token}"].each do |authorization|
              expect { authorize(authorization) }.to raise_error(Unauthorized)
            end
            expect(WebMock).not_to have_requested(:get, me_url)
          end
        end

        context 'when Identity refuses the token' do
          it 'raises Unauthorized on any client error' do
            [401, 403, 404].each do |status|
              stub_me(status: status, body: '{}')

              expect { authorize }.to raise_error(Unauthorized)
            end
          end

          it 'remembers nothing' do
            stub_me(status: 401, body: '{}')

            expect { authorize }.to raise_error(Unauthorized)
            expect(cache.entries).to be_empty
          end
        end

        context 'when Identity cannot tell' do
          it 'raises Unavailable on a server error or a rate limit' do
            [429, 500, 502, 503].each do |status|
              stub_me(status: status, body: '{}')

              expect { authorize }.to raise_error(Unavailable)
            end
          end

          it 'raises Unavailable when it does not answer' do
            stub_request(:get, me_url).to_timeout
            expect { authorize }.to raise_error(Unavailable)

            stub_request(:get, me_url).to_raise(Errno::ECONNREFUSED)
            expect { authorize }.to raise_error(Unavailable)
          end

          it 'raises Unavailable on a body that is no JSON object' do
            [['<html></html>', 'text/html'], ['{"id":', 'application/json'], ['[]', 'application/json']].each do |body, type|
              stub_me(body: body, content_type: type)

              expect { authorize }.to raise_error(Unavailable)
            end
          end

          it 'raises Unavailable on a body without id' do
            stub_me(body: '{}')

            expect { authorize }.to raise_error(Unavailable)
          end
        end

        context 'when the cache fails' do
          let(:cache) { BrokenCache.new }

          it 'asks /me on every request, and logs it' do
            stub_me

            2.times { expect(authorize.current_resource).to eq FakeUser.new(42) }
            expect(WebMock).to have_requested(:get, me_url).twice
            expect(logger).to have_received(:warn).at_least(:twice)
          end
        end
      end

      describe '#refresh!' do
        it 'asks /me even for a remembered token, and remembers it again' do
          stub_me
          authorize

          identity = provider
          identity.refresh!

          expect(identity.current_resource).to eq FakeUser.new(42)
          expect(WebMock).to have_requested(:get, me_url).twice
          expect(cache.entries).to eq(described_class.cache_key(token) => 42)
        end

        it 'refuses a missing bearer without asking /me' do
          expect { provider(nil).refresh! }.to raise_error(Unauthorized)
          expect(WebMock).not_to have_requested(:get, me_url)
        end
      end

      describe '#current_resource' do
        it 'is nil before authorization' do
          expect(provider.current_resource).to be_nil
        end
      end

      describe '#revoke_access!' do
        let(:revoke_url) { 'https://identity.test/oauth/revoke' }

        before do
          stub_me
          authorize
          stub_request(:post, revoke_url)
        end

        it 'revokes the token on Identity' do
          provider.revoke_access!

          expect(WebMock).to have_requested(:post, revoke_url).with(body: { token: token }.to_json)
        end

        it 'forgets the token' do
          provider.revoke_access!

          expect(cache.entries).to be_empty
        end

        it 'raises Unavailable when Identity does not answer or fails, and keeps the token' do
          [-> { stub_request(:post, revoke_url).to_timeout }, -> { stub_request(:post, revoke_url).to_return(status: 500) }].each do |stub|
            stub.call

            expect { provider.revoke_access! }.to raise_error(Unavailable)
            expect(cache.entries).not_to be_empty
          end
        end
      end

      describe '.token_from' do
        it 'is the bearer token of an Authorization header' do
          expect(described_class.token_from("Bearer #{token}")).to eq token
        end

        it 'is nil for anything but a single bearer token' do
          [nil, '', 'Bearer ', 'Bearer a b', "Basic #{token}", "xBearer #{token}"].each do |header|
            expect(described_class.token_from(header)).to be_nil
          end
        end
      end

      describe '.cached_resource_id' do
        it 'is the id remembered for the token' do
          stub_me
          authorize

          expect(described_class.cached_resource_id(token)).to eq 42
        end

        it 'is nil for an unknown or blank token, or when the cache fails' do
          expect(described_class.cached_resource_id('unknown')).to be_nil
          expect(described_class.cached_resource_id(nil)).to be_nil
          Identity::Gateway.configuration.cache = BrokenCache.new
          expect(described_class.cached_resource_id(token)).to be_nil
        end
      end
    end
  end
end
