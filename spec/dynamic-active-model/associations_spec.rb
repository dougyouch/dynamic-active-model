# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Associations do
  include_context 'database'

  describe '#build!' do
    subject { relations.build! }

    before do
      relations.add_foreign_key('websites', 'company_website_id', 'company_website')
      relations.add_foreign_key('users', 'employee_user_id', 'employee_user')
    end

    it 'creates relationships between models' do
      subject
      expect(has_association?(base_module.const_get('Employment'), :user)).to be(true)
      expect(has_association?(base_module.const_get('User'), :employments)).to be(true)
    end

    it 'creates relationships for additional foreign keys' do
      subject
      expect(has_association?(base_module.const_get('Company'), :website)).to be(true)
      expect(has_association?(base_module.const_get('Company'), :company_website)).to be(true)
      expect(has_association?(base_module.const_get('Website'), :companies)).to be(true)
      expect(has_association?(base_module.const_get('Website'), :company_website_companies)).to be(true)
    end

    it 'creates has one relationships' do
      subject
      expect(has_association?(base_module.const_get('User'), :user_rollup)).to be(true)
    end

    it 'creates has one relationships for additional foreign keys' do
      subject
      expect(has_association?(base_module.const_get('User'), :employee_user)).to be(true)
    end

    it 'creates has_and_belongs_to_many relationships' do
      subject
      expect(has_association?(base_module.const_get('Job'), :websites)).to be(true)
      expect(has_association?(base_module.const_get('Website'), :jobs)).to be(true)
    end
  end
end
