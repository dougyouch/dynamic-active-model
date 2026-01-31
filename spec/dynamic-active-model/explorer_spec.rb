# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Explorer do
  include_context 'database'

  describe '.explore' do
    subject { described_class.explore(base_module, connection_options, skip_tables, relationships) }

    let(:skip_tables) { [] }
    let(:relationships) { {} }

    it 'returns a Database instance' do
      expect(subject).to be_a(DynamicActiveModel::Database)
    end

    it 'creates models in the base module' do
      subject
      expect(base_module.const_defined?(:User)).to be(true)
      expect(base_module.const_defined?(:Company)).to be(true)
      expect(base_module.const_defined?(:Job)).to be(true)
    end

    it 'builds relationships between models' do
      subject
      user_model = base_module.const_get(:User)
      expect(has_association?(user_model, :employments)).to be(true)
    end

    context 'with skip_tables' do
      let(:skip_tables) { ['tmp_load_data_table'] }

      it 'skips specified tables' do
        subject
        expect(base_module.const_defined?(:TmpLoadDataTable)).to be(false)
      end

      it 'still creates other models' do
        subject
        expect(base_module.const_defined?(:User)).to be(true)
      end
    end

    context 'with wildcard skip_tables' do
      let(:skip_tables) { ['stats_*'] }

      it 'skips tables matching the wildcard pattern' do
        subject
        expect(base_module.const_defined?(:StatsEmploymentDuration)).to be(false)
        expect(base_module.const_defined?(:StatsCompanyEmployment)).to be(false)
      end

      it 'still creates non-matching models' do
        subject
        expect(base_module.const_defined?(:User)).to be(true)
        expect(base_module.const_defined?(:Company)).to be(true)
      end
    end

    context 'with custom relationships' do
      let(:relationships) do
        {
          'websites' => {
            'company_website_id' => 'company_website'
          }
        }
      end

      it 'adds custom foreign key relationships' do
        subject
        company_model = base_module.const_get(:Company)
        # The company has company_website_id column which creates a belongs_to
        # to the website model with the custom relationship name
        expect(has_association?(company_model, :company_website)).to be(true)
      end
    end
  end

  describe '.create_models!' do
    subject { described_class.create_models!(base_module, connection_options, skip_tables) }

    let(:skip_tables) { [] }

    it 'returns a Database instance' do
      expect(subject).to be_a(DynamicActiveModel::Database)
    end

    it 'creates models in the base module' do
      subject
      expect(base_module.const_defined?(:User)).to be(true)
    end

    context 'with string skip_tables' do
      let(:skip_tables) { ['tmp_load_data_table'] }

      it 'skips the specified table' do
        subject
        expect(base_module.const_defined?(:TmpLoadDataTable)).to be(false)
      end
    end

    context 'with wildcard skip_tables' do
      let(:skip_tables) { ['stats_*'] }

      it 'converts wildcard to regex and skips matching tables' do
        subject
        expect(base_module.const_defined?(:StatsEmploymentDuration)).to be(false)
        expect(base_module.const_defined?(:StatsCompanyEmployment)).to be(false)
      end
    end
  end

  describe '.build_relationships!' do
    subject { described_class.build_relationships!(database_instance, relationships) }

    let(:database_instance) do
      db = DynamicActiveModel::Database.new(base_module, connection_options)
      db.create_models!
      db
    end
    let(:relationships) { {} }

    it 'creates standard relationships' do
      subject
      user_model = base_module.const_get(:User)
      employment_model = base_module.const_get(:Employment)
      expect(has_association?(user_model, :employments)).to be(true)
      expect(has_association?(employment_model, :user)).to be(true)
    end

    context 'with custom relationships' do
      let(:relationships) do
        {
          'websites' => {
            'company_website_id' => 'company_website'
          }
        }
      end

      it 'adds custom foreign key relationships' do
        subject
        company_model = base_module.const_get(:Company)
        website_model = base_module.const_get(:Website)
        expect(has_association?(company_model, :company_website)).to be(true)
        expect(has_association?(website_model, :company_website_companies)).to be(true)
      end
    end

    context 'with multiple custom relationships for same table' do
      let(:relationships) do
        {
          'websites' => {
            'company_website_id' => 'company_website'
          },
          'users' => {
            'employee_user_id' => 'employee_user'
          }
        }
      end

      it 'adds all custom foreign key relationships' do
        subject
        company_model = base_module.const_get(:Company)
        user_model = base_module.const_get(:User)
        expect(has_association?(company_model, :company_website)).to be(true)
        expect(has_association?(user_model, :employee_user)).to be(true)
      end
    end
  end
end
