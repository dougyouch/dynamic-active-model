# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Database do
  include_context 'database'

  let(:example_table_name) { 'tmp_load_data_table' }
  let(:example_table_names) { ['foo', 'bar'] }
  let(:all_example_table_names) { example_table_names.push(example_table_name).sort }
  let(:example_table_regex) { /^stats_/ }

  context '#skip_table?' do
    describe 'table names' do
      before(:each) do
        database.skip_table example_table_name
        database.skip_tables example_table_names
      end

      it 'skips table' do
        expect(database.send(:skip_table?, example_table_name)).to eq(true)
      end

      it 'skips tables from an array' do
        expect(database.send(:skip_table?, example_table_names.first)).to eq(true)
      end

      it 'does not skip the table' do
        expect(database.send(:skip_table?, 'users')).to eq(false)
      end

      it 'returns tables to skip' do
        expect(database.skipped_tables.sort).to eq(all_example_table_names)
      end
    end

    describe 'table names' do
      before(:each) do
        database.skip_table example_table_regex
      end

      it 'skips table' do
        expect(database.send(:skip_table?, 'stats_employment_durations')).to eq(true)
        expect(database.send(:skip_table?, 'stats_company_employments')).to eq(true)
      end

      it 'does not skip the table' do
        expect(database.send(:skip_table?, 'users')).to eq(false)
      end

      it 'returns tables to skip' do
        expect(database.skipped_tables).to eq([example_table_regex])
      end
    end
  end

  context '#include_table?' do
    describe 'table names' do
      before(:each) do
        database.include_table example_table_name
        database.include_tables example_table_names
      end

      it 'includes table' do
        expect(database.send(:include_table?, example_table_name)).to eq(true)
      end

      it 'includes tables from an array' do
        expect(database.send(:include_table?, example_table_names.first)).to eq(true)
      end

      it 'does not include the table' do
        expect(database.send(:include_table?, 'users')).to eq(false)
      end

      it 'returns tables to include' do
        expect(database.included_tables.sort).to eq(all_example_table_names)
      end
    end

    describe 'table names' do
      before(:each) do
        database.include_table example_table_regex
      end

      it 'includes table' do
        expect(database.send(:include_table?, 'stats_employment_durations')).to eq(true)
        expect(database.send(:include_table?, 'stats_company_employments')).to eq(true)
      end

      it 'does not include the table' do
        expect(database.send(:include_table?, 'users')).to eq(false)
      end

      it 'returns tables to include' do
        expect(database.included_tables).to eq([example_table_regex])
      end
    end
  end

  context '#create_models!' do
    before(:each) do
      database.skip_table example_table_name
      database.skip_table example_table_regex
      database.table_class_name 'websites', 'CompanyWebsite'
    end

    let(:expected_classes) do
      [
        :User,
        :Company,
        :Job,
        :CompanyWebsite,
        :Employment
      ]
    end
    let(:undefined_classes) do
      [
        :Website,
        :StatsEmploymentDuration,
        :StatsCompanyEmployment,
        :TmpLoadDataTable
      ]
    end
    subject { database.create_models! }

    it 'creates ActiveRecord models for database' do
      subject
      expect(expected_classes.all? { |name| base_module.const_defined?(name) }).to eq(true)
      expect(undefined_classes.all? { |name| ! base_module.const_defined?(name) }).to eq(true)
    end

    describe 'classes have active record functionality' do
      before(:each) do
        database.create_models!
      end
      subject { base_module.const_get(:User) }

      it 'primary_key' do
        expect(subject.primary_key).to eq('id')
      end

      it 'table_name' do
        expect(subject.table_name).to eq('users')
      end
    end
  end

  context '#create_models!' do
    before(:each) do
      database.include_table 'users'
    end

    let(:expected_classes) do
      [
        :User
      ]
    end
    let(:undefined_classes) do
      [
        :Company,
        :Job,
        :Employment,
        :Website,
        :StatsEmploymentDuration,
        :StatsCompanyEmployment,
        :TmpLoadDataTable
      ]
    end
    subject { database.create_models! }

    it 'creates ActiveRecord models for database' do
      subject
      expect(expected_classes.all? { |name| base_module.const_defined?(name) }).to eq(true)
      expect(undefined_classes.all? { |name| ! base_module.const_defined?(name) }).to eq(true)
    end
  end

  context 'disable_standard_table_inheritance!' do
    subject { database.disable_standard_table_inheritance! }
    let(:company_model) { database.models.detect { |model| model.table_name == 'companies' } }

    before do
      database.create_models!
      subject
    end

    it { expect(company_model.inheritance_column).to eq('_type_disabled') }
  end
end
