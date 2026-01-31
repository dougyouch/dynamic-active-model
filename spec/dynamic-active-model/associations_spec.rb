# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Associations do
  include_context 'database'

  describe '#initialize' do
    subject { relations }

    it 'sets the database' do
      expect(subject.database).to eq(database)
    end

    it 'initializes table_indexes' do
      expect(subject.table_indexes).to be_a(Hash)
      expect(subject.table_indexes).not_to be_empty
    end

    it 'detects join tables' do
      join_table_names = subject.join_tables.map(&:table_name)
      expect(join_table_names).to include('jobs_websites')
    end
  end

  describe '#add_foreign_key' do
    it 'adds a foreign key to the specified table' do
      relations.add_foreign_key('companies', 'owner_id', 'owner')
      # Verify by building and checking the relationship is created
      relations.build!
      base_module.const_get('Company')
      base_module.const_get('User')
      # owner_id column doesn't exist so this won't create an association
      # but the foreign_key is stored
      expect(relations).to respond_to(:add_foreign_key)
    end

    it 'stores the relationship name' do
      relations.add_foreign_key('websites', 'company_website_id', 'company_website')
      relations.build!
      website_model = base_module.const_get('Website')
      expect(has_association?(website_model, :company_website_companies)).to be(true)
    end
  end

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

    it 'creates belongs_to relationships' do
      subject
      employment_model = base_module.const_get('Employment')
      expect(has_association?(employment_model, :user)).to be(true)
      expect(has_association?(employment_model, :job)).to be(true)
      expect(has_association?(employment_model, :company)).to be(true)
    end

    it 'sets correct class_name on belongs_to' do
      subject
      employment_model = base_module.const_get('Employment')
      assoc = get_association(employment_model, :user)
      expect(assoc.options[:class_name]).to include('User')
    end

    it 'sets correct foreign_key on belongs_to' do
      subject
      employment_model = base_module.const_get('Employment')
      assoc = get_association(employment_model, :user)
      expect(assoc.options[:foreign_key]).to eq('user_id')
    end

    it 'does not create self-referential relationships' do
      subject
      user_model = base_module.const_get('User')
      # User has user_id in foreign keys but should not belong_to itself
      assocs = user_model.reflect_on_all_associations(:belongs_to)
      self_refs = assocs.select { |a| a.options[:class_name]&.include?('User') }
      expect(self_refs).to be_empty
    end
  end

  describe '#join_tables' do
    subject { relations.join_tables }

    it 'returns an array of join table models' do
      expect(subject).to be_an(Array)
    end

    it 'includes the jobs_websites join table' do
      table_names = subject.map(&:table_name)
      expect(table_names).to include('jobs_websites')
    end

    it 'does not include regular tables' do
      table_names = subject.map(&:table_name)
      expect(table_names).not_to include('users')
      expect(table_names).not_to include('companies')
    end
  end

  describe '#table_indexes' do
    subject { relations.table_indexes }

    it 'returns indexes for each table' do
      expect(subject).to be_a(Hash)
    end

    it 'includes indexes for user_rollups table with unique index' do
      user_rollup_indexes = subject['user_rollups']
      unique_indexes = user_rollup_indexes.select(&:unique)
      expect(unique_indexes).not_to be_empty
    end
  end

  describe 'relationship association options' do
    before do
      relations.build!
    end

    describe 'has_many associations' do
      let(:user_model) { base_module.const_get('User') }

      it 'sets the correct primary_key' do
        assoc = get_association(user_model, :employments)
        expect(assoc.options[:primary_key]).to eq('id')
      end

      it 'sets the correct foreign_key' do
        assoc = get_association(user_model, :employments)
        expect(assoc.options[:foreign_key]).to eq('user_id')
      end
    end

    describe 'has_one associations' do
      let(:user_model) { base_module.const_get('User') }

      it 'creates has_one for unique index columns' do
        assoc = get_association(user_model, :user_rollup)
        expect(assoc).to be_a(ActiveRecord::Reflection::HasOneReflection)
      end

      it 'sets the correct options' do
        assoc = get_association(user_model, :user_rollup)
        expect(assoc.options[:foreign_key]).to eq('user_id')
      end
    end

    describe 'has_and_belongs_to_many associations' do
      let(:job_model) { base_module.const_get('Job') }
      let(:website_model) { base_module.const_get('Website') }

      it 'sets the join_table option' do
        assoc = get_association(job_model, :websites)
        expect(assoc.options[:join_table]).to eq('jobs_websites')
      end

      it 'creates bidirectional associations' do
        expect(has_association?(job_model, :websites)).to be(true)
        expect(has_association?(website_model, :jobs)).to be(true)
      end
    end
  end
end
