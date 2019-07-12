# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Database do
  include_context 'database'

  let(:skip_table_name) { 'tmp_load_data_table' }
  let(:skip_table_regex) { /^stats_/ }

  context '#skip_table?' do
    describe 'table names' do
      before(:each) do
        database.skip_table skip_table_name
      end

      it 'skips table' do
        expect(database.send(:skip_table?, skip_table_name)).to eq(true)
      end

      it 'does not skip the table' do
        expect(database.send(:skip_table?, 'users')).to eq(false)
      end

      it 'returns tables to skip' do
        expect(database.skip_tables).to eq([skip_table_name])
      end
    end

    describe 'table names' do
      before(:each) do
        database.skip_table skip_table_regex
      end

      it 'skips table' do
        expect(database.send(:skip_table?, 'stats_employment_durations')).to eq(true)
        expect(database.send(:skip_table?, 'stats_company_employments')).to eq(true)
      end

      it 'does not skip the table' do
        expect(database.send(:skip_table?, 'users')).to eq(false)
      end

      it 'returns tables to skip' do
        expect(database.skip_tables).to eq([skip_table_regex])
      end
    end
  end

  context '#create_models!' do
    before(:each) do
      database.skip_table skip_table_name
      database.skip_table skip_table_regex
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
end
