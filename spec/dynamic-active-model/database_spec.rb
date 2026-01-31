# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Database do
  include_context 'database'

  let(:example_table_name) { 'tmp_load_data_table' }
  let(:example_table_names) { %w[foo bar] }
  let(:all_example_table_names) { example_table_names.push(example_table_name).sort }
  let(:example_table_regex) { /^stats_/ }

  describe '#skip_table?' do
    describe 'table names' do
      before do
        database.skip_table example_table_name
        database.skip_tables example_table_names
      end

      it 'skips table' do
        expect(database.send(:skip_table?, example_table_name)).to be(true)
      end

      it 'skips tables from an array' do
        expect(database.send(:skip_table?, example_table_names.first)).to be(true)
      end

      it 'does not skip the table' do
        expect(database.send(:skip_table?, 'users')).to be(false)
      end

      it 'returns tables to skip' do
        expect(database.skipped_tables.sort).to eq(all_example_table_names)
      end
    end

    describe 'table names' do
      before do
        database.skip_table example_table_regex
      end

      it 'skips table' do
        expect(database.send(:skip_table?, 'stats_employment_durations')).to be(true)
        expect(database.send(:skip_table?, 'stats_company_employments')).to be(true)
      end

      it 'does not skip the table' do
        expect(database.send(:skip_table?, 'users')).to be(false)
      end

      it 'returns tables to skip' do
        expect(database.skipped_tables).to eq([example_table_regex])
      end
    end
  end

  describe '#include_table?' do
    describe 'table names' do
      before do
        database.include_table example_table_name
        database.include_tables example_table_names
      end

      it 'includes table' do
        expect(database.send(:include_table?, example_table_name)).to be(true)
      end

      it 'includes tables from an array' do
        expect(database.send(:include_table?, example_table_names.first)).to be(true)
      end

      it 'does not include the table' do
        expect(database.send(:include_table?, 'users')).to be(false)
      end

      it 'returns tables to include' do
        expect(database.included_tables.sort).to eq(all_example_table_names)
      end
    end

    describe 'table names' do
      before do
        database.include_table example_table_regex
      end

      it 'includes table' do
        expect(database.send(:include_table?, 'stats_employment_durations')).to be(true)
        expect(database.send(:include_table?, 'stats_company_employments')).to be(true)
      end

      it 'does not include the table' do
        expect(database.send(:include_table?, 'users')).to be(false)
      end

      it 'returns tables to include' do
        expect(database.included_tables).to eq([example_table_regex])
      end
    end
  end

  describe '#create_models!' do
    subject { database.create_models! }

    before do
      database.skip_table example_table_name
      database.skip_table example_table_regex
      database.table_class_name 'websites', 'CompanyWebsite'
    end

    let(:expected_classes) do
      %i[
        User
        Company
        Job
        CompanyWebsite
        Employment
      ]
    end
    let(:undefined_classes) do
      %i[
        Website
        StatsEmploymentDuration
        StatsCompanyEmployment
        TmpLoadDataTable
      ]
    end

    it 'creates ActiveRecord models for database' do
      subject
      expect(expected_classes.all? { |name| base_module.const_defined?(name) }).to be(true)
      expect(undefined_classes.all? { |name| !base_module.const_defined?(name) }).to be(true)
    end

    describe 'classes have active record functionality' do
      subject { base_module.const_get(:User) }

      before do
        database.create_models!
      end

      it 'primary_key' do
        expect(subject.primary_key).to eq('id')
      end

      it 'table_name' do
        expect(subject.table_name).to eq('users')
      end
    end
  end

  describe '#create_models!' do
    subject { database.create_models! }

    before do
      database.include_table 'users'
    end

    let(:expected_classes) do
      [
        :User
      ]
    end
    let(:undefined_classes) do
      %i[
        Company
        Job
        Employment
        Website
        StatsEmploymentDuration
        StatsCompanyEmployment
        TmpLoadDataTable
      ]
    end

    it 'creates ActiveRecord models for database' do
      subject
      expect(expected_classes.all? { |name| base_module.const_defined?(name) }).to be(true)
      expect(undefined_classes.all? { |name| !base_module.const_defined?(name) }).to be(true)
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

  describe '#get_model' do
    subject { database.get_model(table_name) }

    before do
      database.create_models!
    end

    let(:table_name) { :users }

    it { expect(subject.nil?).to be(false) }

    describe 'invalid table' do
      let(:table_name) { :not_a_valid_table_name }

      it { expect(subject.nil?).to be(true) }
    end
  end

  describe '#get_model!' do
    subject { database.get_model!(table_name) }

    before do
      database.create_models!
    end

    let(:table_name) { :users }

    it { expect(subject.nil?).to be(false) }

    describe 'invalid table' do
      let(:table_name) { :not_a_valid_table_name }

      it { expect { subject }.to raise_error(DynamicActiveModel::ModelNotFound) }
    end
  end

  describe '#update_model' do
    subject do
      database.update_model(:users, 'spec/support/db/extensions/users.ext.rb') do
        attr_accessor :display_name
      end
      database.get_model!(:users)
    end

    before do
      database.create_models!
    end

    it { expect(subject.method_defined?(:display_name)).to be(true) }
    it { expect(subject.method_defined?(:method_does_not_exist)).to be(false) }
    it { expect(subject.method_defined?(:my_middle_name)).to be(true) }
  end

  describe '#update_all_models' do
    subject do
      database.update_all_models('spec/support/db/extensions')
      database.get_model!(:users)
    end

    before do
      database.create_models!
    end

    it { expect(subject.method_defined?(:display_name)).to be(false) }
    it { expect(subject.method_defined?(:method_does_not_exist)).to be(false) }
    it { expect(subject.method_defined?(:my_middle_name)).to be(true) }
  end
end
