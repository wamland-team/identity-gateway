require 'spec_helper'

module Identity
  module Gateway
    RSpec.describe Configuration do
      describe '#provider_url' do
        it 'has no default value' do
          expect(Configuration.new.provider_url).to be_nil
        end
      end

      describe '#model' do
        it 'has no default value' do
          expect(Configuration.new.model).to be_nil
        end
      end

      describe '#segment_path' do
        it 'has a default value' do
          expect(Configuration.new.segment_path).to eq '/me'
        end
      end
    end
  end
end
