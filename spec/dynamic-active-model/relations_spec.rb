# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Relations do
  include_context 'database'

  context '#build!' do
    before(:each) do
      relations.add_foreign_key('websites', 'company_website_id', 'company_website')
    end
    subject { relations.build! }

    it 'creates relationships between models' do
      subject
      expect(has_association?(base_module.const_get('Employment'), :user)).to eq(true)
      expect(has_association?(base_module.const_get('User'), :employments)).to eq(true)
    end

    it 'creates relationships for additional foreign keys' do
      subject
      expect(has_association?(base_module.const_get('Company'), :website)).to eq(true)
      expect(has_association?(base_module.const_get('Company'), :company_website)).to eq(true)
      expect(has_association?(base_module.const_get('Website'), :companies)).to eq(true)
    end
  end
end
