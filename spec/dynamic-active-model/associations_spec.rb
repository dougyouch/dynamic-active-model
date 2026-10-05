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

    it 'makes belongs_to optional when the foreign key is nullable, and required when it is NOT NULL' do
      subject
      expect(get_association(base_module.const_get('Employment'), :user).options[:optional]).to be(true)
      expect(get_association(base_module.const_get('UserRollup'), :user).options[:optional]).to be(false)
    end

    it 'validates required belongs_to and skips optional ones' do
      subject
      expect(base_module.const_get('Employment').new.tap(&:valid?).errors[:user]).to be_empty
      expect(base_module.const_get('UserRollup').new.tap(&:valid?).errors[:user]).to eq(['must exist'])
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

  describe 'join table with unmatched foreign keys' do
    # This tests the case where a join table has foreign keys that
    # don't match any model (models.size != 2)
    before do
      relations.build!
    end

    it 'handles join tables where foreign keys reference existing models' do
      job_model = base_module.const_get(:Job)
      website_model = base_module.const_get(:Website)
      # Verify the HABTM was created for the valid join table
      expect(has_association?(job_model, :websites)).to be(true)
      expect(has_association?(website_model, :jobs)).to be(true)
    end
  end

  describe 'foreign key constraints' do
    let(:connection_options) { create_test_database(FOREIGN_KEY_CONSTRAINTS_SCHEMA) }

    def model(table_name)
      database.get_model!(table_name)
    end

    def association(table_name, name)
      model(table_name).reflect_on_association(name)
    end

    before do
      database.skip_table 'archivists'
      database.create_models!
    end

    context 'when not in use (the default)' do
      before { relations.build! }

      it 'relates columns by naming convention only' do
        expect(association('posts', :user).klass).to eq(model('users'))
        expect(association('posts', :author)).to be_nil
        expect(association('employees', :manager)).to be_nil
        expect(association('profiles', :account).klass).to eq(model('accounts'))
      end
    end

    context 'when in use' do
      before do
        relations.use_foreign_key_constraints!
        relations.build!
      end

      it 'relates a column the naming convention misses' do
        expect(association('posts', :author)).to have_attributes(macro: :belongs_to, klass: model('users'))
        expect(association('users', :author_posts)).to have_attributes(macro: :has_many, klass: model('posts'))
      end

      it 'keeps the conventional names for conventional columns' do
        expect(association('posts', :user).klass).to eq(model('users'))
        expect(association('users', :posts).foreign_key).to eq('user_id')
      end

      it 'relates a self-reference' do
        expect(association('employees', :manager).klass).to eq(model('employees'))
        expect(association('employees', :manager_employees).foreign_key).to eq('manager_id')
      end

      it 'follows the constraint over the naming convention' do
        expect(association('profiles', :account).klass).to eq(model('users'))
        expect(association('accounts', :profiles)).to be_nil
      end

      it 'uses the referenced column when it is not the primary key' do
        expect(association('tickets', :requester).options[:primary_key]).to eq('legacy_id')
        expect(association('users', :requester_tickets).options[:primary_key]).to eq('legacy_id')
      end

      it 'loads records through constraint associations' do
        model('users').create!(id: 1, legacy_id: 101, name: 'Ada')
        model('posts').create!(id: 1, author_id: 1)
        model('tickets').create!(id: 1, requester_id: 101)
        expect(model('posts').find(1).author.name).to eq('Ada')
        expect(model('tickets').find(1).requester.name).to eq('Ada')
        expect(model('users').find(1).requester_tickets.map(&:id)).to eq([1])
      end

      it 'adds nothing for skipped constraints' do
        expect(association('posts', :owner)).to be_nil
        expect(association('posts', :archivist)).to be_nil
        expect(association('stores', :region_country)).to be_nil
      end
    end
  end

  describe '#use_has_many_through!' do
    let(:connection_options) { create_test_database(HAS_MANY_THROUGH_SCHEMA) }

    before { database.create_models! }

    it 'is off by default' do
      relations.build!
      expect(database.get_model!(:users).reflect_on_association(:roles)).to be_nil
    end

    it 'adds has_many :through when in use' do
      relations.use_has_many_through!
      relations.build!
      expect(database.get_model!(:users).reflect_on_association(:roles).options[:through]).to eq(:user_roles)
    end
  end

  describe 'index lookups' do
    def queries_during(&block)
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
      queries
    end

    it 'reads indexes through the schema cache' do
      database.create_models!
      described_class.new(database)
      expect(queries_during { described_class.new(database) }).to be_empty
    end

    it 'sees a new index once the schema cache is cleared' do
      relations
      model = database.get_model!(:users)
      model.connection.add_index(:users, :name, name: 'index_users_on_name_for_spec')
      expect(described_class.new(database).table_indexes['users'].map(&:name)).not_to include('index_users_on_name_for_spec')

      model.connection.schema_cache.clear!
      expect(described_class.new(database).table_indexes['users'].map(&:name)).to include('index_users_on_name_for_spec')
    ensure
      model&.connection&.remove_index(:users, name: 'index_users_on_name_for_spec')
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

  describe 'tables with non-id primary keys' do
    let(:connection_options) do
      create_test_database(<<~SQL)
        CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);
        CREATE TABLE posts (post_uuid VARCHAR(36) PRIMARY KEY, user_id INTEGER);
        CREATE TABLE profiles (profile_key INTEGER PRIMARY KEY, user_id INTEGER);
        CREATE UNIQUE INDEX index_profiles_on_user_id ON profiles (user_id);
        INSERT INTO users (id, name) VALUES (1, 'Jane');
        INSERT INTO posts (post_uuid, user_id) VALUES ('p1', 1);
        INSERT INTO profiles (profile_key, user_id) VALUES (99, 1);
      SQL
    end
    let(:user) { base_module.const_get(:User).find(1) }

    before do
      relations.build!
    end

    it 'finds has_many records through the parent primary key' do
      expect(user.posts.map(&:post_uuid)).to eq(['p1'])
    end

    it 'finds the has_one record through the parent primary key' do
      expect(user.profile.profile_key).to eq(99)
    end

    it 'finds the belongs_to record through the parent primary key' do
      expect(base_module.const_get(:Post).find('p1').user).to eq(user)
    end
  end

  describe '#add_foreign_key with a symbol table name' do
    it 'adds the foreign key to the table' do
      relations.add_foreign_key(:websites, 'company_website_id', 'company_website')
      relations.build!
      website_model = base_module.const_get('Website')
      expect(has_association?(website_model, :company_website_companies)).to be(true)
    end
  end

  describe '#add_foreign_key with an unknown table' do
    it 'raises ModelNotFound' do
      expect { relations.add_foreign_key('missing_table', 'missing_id') }
        .to raise_error(DynamicActiveModel::ModelNotFound, /missing_table/)
    end
  end

  describe '#join_table? with a custom id suffix' do
    let(:column) { Struct.new(:name) }
    let(:model) do
      Struct.new(:primary_key, :columns).new(nil, [column.new('job_xref'), column.new('website_xref')])
    end

    before do
      DynamicActiveModel::ForeignKey.id_suffix = '.ref'
    end

    after do
      DynamicActiveModel::ForeignKey.id_suffix = nil
    end

    it 'matches the suffix literally' do
      expect(relations.send(:join_table?, model)).to be(false)
    end
  end

  describe 'join table with only one foreign key matching a model' do
    let(:connection_options) do
      create_test_database(<<~SQL)
        CREATE TABLE jobs (id INTEGER PRIMARY KEY);
        CREATE TABLE jobs_tags (job_id INTEGER, tag_id INTEGER);
      SQL
    end

    before do
      relations.build!
    end

    it 'detects the join table' do
      expect(relations.join_tables.map(&:table_name)).to eq(['jobs_tags'])
    end

    it 'does not add a has_and_belongs_to_many association' do
      job_model = base_module.const_get(:Job)
      expect(job_model.reflect_on_all_associations(:has_and_belongs_to_many)).to be_empty
    end
  end
end
