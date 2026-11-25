# frozen_string_literal: true

require 'active_record'

# A model whose primary key is no `id` column while it keeps one, as
# payment-gateway's User: `id` answers the uid, `find_by(id:)` reads the
# `id` column.
class UidUser < ActiveRecord::Base
  self.table_name = 'users'
  self.primary_key = 'uid'

  def self.from_oauth_provider(hash)
    find_or_create_by!(uid: hash['id'].to_s)
  end
end

module Identity
  module Gateway
    RSpec.describe Provider do
      let(:token) { 'token-1' }
      let(:cache) { FakeCache.new }

      before(:all) do
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
        ActiveRecord::Schema.verbose = false
        ActiveRecord::Schema.define do
          create_table :users, id: false do |t|
            t.string :uid, primary_key: true
            t.integer :id
          end
        end
      end

      after(:all) { ActiveRecord::Base.remove_connection }

      before do
        Identity::Gateway.configure do |config|
          config.model        = UidUser
          config.provider_url = 'https://identity.test'
          config.cache        = cache
        end
      end

      after { UidUser.delete_all }

      def authorize
        identity = described_class.new(FakeRequest.new({ 'Authorization' => "Bearer #{token}" }))
        identity.authorize!
        identity
      end

      context 'with a model keyed by a column other than id' do
        # The owner's uid is the other record's id column: `id=` would write
        # the uid, hence the raw insert.
        let(:owner) { UidUser.find('7') }

        before do
          UidUser.insert_all!([{ uid: '7', id: 1 }, { uid: '8', id: 7 }])
          stub_request(:get, 'https://identity.test/me')
            .to_return(status: 200, body: { 'id' => 7 }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'remembers the primary key' do
          authorize

          expect(described_class.cached_resource_id(token)).to eq '7'
        end

        it 'resolves a remembered token to its owner, not to the record whose id column matches' do
          authorize

          expect(authorize.current_resource).to eq owner
          expect(WebMock).to have_requested(:get, 'https://identity.test/me').once
        end
      end
    end
  end
end
