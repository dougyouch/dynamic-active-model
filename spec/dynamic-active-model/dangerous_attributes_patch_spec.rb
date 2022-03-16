# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::DangerousAttributesPatch do
  include_context 'database'

  before(:each) do
    database.create_models!
  end

  let(:dangerous_attribute_name) { 'reload' }
  let(:company_model) { database.models.detect { |m| m.table_name == 'companies' } }
  let(:column_names) { company_model.columns.map(&:name) }

  context '.attribute_names' do
    subject { company_model.attribute_names }

    it 'excludes the dangerous attribue name' do
      expect(subject.include?(dangerous_attribute_name)).to eq(false)
    end
  end
end
