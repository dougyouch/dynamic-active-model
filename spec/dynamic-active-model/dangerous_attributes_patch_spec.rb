# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::DangerousAttributesPatch do
  include_context 'database'

  before do
    database.create_models!
  end

  let(:company_model) { database.models.detect { |m| m.table_name == 'companies' } }
  let(:employee_user_model) { database.models.detect { |m| m.table_name == 'employee_users' } }
  let(:column_names) { company_model.columns.map(&:name) }

  describe '.included' do
    it 'is included in created models' do
      expect(company_model.ancestors).to include(described_class)
    end
  end

  describe '.attribute_names' do
    subject { company_model.attribute_names }

    it 'excludes the dangerous reload attribute' do
      expect(subject.include?('reload')).to be(false)
    end

    it 'excludes the dangerous save attribute' do
      expect(subject.include?('save')).to be(false)
    end

    it 'excludes the dangerous hash attribute' do
      expect(subject.include?('hash')).to be(false)
    end

    it 'includes safe attributes' do
      expect(subject.include?('name')).to be(true)
      expect(subject.include?('type')).to be(true)
    end
  end

  describe 'boolean column handling' do
    subject { employee_user_model.attribute_names }

    # The super_user column is a boolean, which generates both
    # super_user and super_user? methods
    it 'handles boolean columns correctly' do
      # super_user is not a dangerous attribute name
      expect(subject.include?('super_user')).to be(true)
    end
  end

  describe '.ignored_columns' do
    subject { company_model.ignored_columns }

    it 'contains the dangerous column names' do
      expect(subject).to include('reload')
      expect(subject).to include('save')
      expect(subject).to include('hash')
    end
  end

  describe 'model functionality with dangerous columns' do
    it 'does not raise error when accessing safe attributes' do
      instance = company_model.new
      expect { instance.name }.not_to raise_error
    end

    it 'excludes dangerous columns from column_names' do
      # In modern ActiveRecord, column_names also respects ignored_columns
      expect(company_model.column_names).not_to include('reload')
      expect(company_model.column_names).not_to include('save')
      expect(company_model.column_names).not_to include('hash')
    end

    it 'allows standard ActiveRecord methods to work' do
      # reload is a standard ActiveRecord method that should still work
      instance = company_model.new
      expect(instance).to respond_to(:reload)
    end
  end
end
