# frozen_string_literal: true

require 'spec_helper'

module Identity
  module Gateway
    RSpec.describe Configuration do
      describe '#model' do
        it 'has a default value' do
          expect(Configuration.new.model).to eq 'User'
        end
      end

      describe '#provider_url' do
        it 'has no default value' do
          expect(Configuration.new.provider_url).to be_nil
        end
      end

      describe '#identity_path' do
        it 'has a default value' do
          expect(Configuration.new.identity_path).to eq '/me'
        end
      end

      describe '#version_header' do
        it 'has no default value' do
          expect(Configuration.new.version_header).to be_nil
        end
      end
    end
  end
end
