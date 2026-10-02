# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel do
  describe '.deprecator' do
    it 'is a memoized ActiveSupport::Deprecation for this gem' do
      expect(described_class.deprecator).to be_a(ActiveSupport::Deprecation)
      expect(described_class.deprecator.gem_name).to eq('dynamic-active-model')
      expect(described_class.deprecator).to equal(described_class.deprecator)
    end
  end
end
