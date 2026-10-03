# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Setup do
  include_context 'database'

  let(:db_module) do
    base_module.include described_class
    base_module
  end

  describe '#connection_options' do
    subject { db_module.connection_options }

    it 'default is nil' do
      expect(subject).to be_nil
    end

    describe 'with #connection_options=' do
      before do
        db_module.connection_options(DB_CONFIG)
      end

      it 'set to DB_CONFIG' do
        expect(subject).to eq(DB_CONFIG)
      end
    end
  end

  describe '#parent_class' do
    subject { db_module.parent_class }

    it 'default is nil' do
      expect(subject).to be_nil
    end

    describe 'with #parent_class=' do
      before do
        db_module.parent_class(ActiveRecord::Base)
      end

      it 'set to the class' do
        expect(subject).to eq(ActiveRecord::Base)
      end
    end
  end

  describe '#create_models! with a parent class' do
    let(:parent_class) do
      base_module.const_set(:Parent, Class.new(ActiveRecord::Base) { self.abstract_class = true })
      base_module::Parent.tap { |kls| kls.establish_connection(DB_CONFIG) }
    end

    before do
      db_module.parent_class(parent_class)
      db_module.create_models!
    end

    it 'builds models that inherit from the parent class' do
      expect(db_module::User.ancestors).to include(parent_class)
      expect(db_module::User.connection_pool).to equal(parent_class.connection_pool)
    end
  end

  describe '#foreign_key_constraints' do
    it 'defaults to false' do
      expect(db_module.foreign_key_constraints).to be(false)
    end

    context 'when enabled' do
      before do
        db_module.connection_options(create_test_database(FOREIGN_KEY_CONSTRAINTS_SCHEMA))
        db_module.skip_tables ['archivists']
        db_module.foreign_key_constraints true
        db_module.create_models!
      end

      it 'relates columns through constraints' do
        expect(db_module.foreign_key_constraints).to be(true)
        expect(db_module::Employee.reflect_on_association(:manager).klass).to eq(db_module::Employee)
      end
    end
  end

  describe '#has_many_through' do
    it 'defaults to false' do
      expect(db_module.has_many_through).to be(false)
    end

    context 'when enabled' do
      before do
        db_module.connection_options(create_test_database(HAS_MANY_THROUGH_SCHEMA))
        db_module.has_many_through true
        db_module.create_models!
      end

      it 'adds has_many :through across join models' do
        expect(db_module.has_many_through).to be(true)
        expect(db_module::User.reflect_on_association(:roles).options[:through]).to eq(:user_roles)
      end
    end
  end

  describe '#extensions_path' do
    subject { db_module.extensions_path }

    it 'default is nil' do
      expect(subject).to be_nil
    end

    describe 'with #extensions_path=' do
      let(:new_extensions_path) { 'lib/db/extensions' }

      before do
        db_module.extensions_path(new_extensions_path)
      end

      it 'set to new path' do
        expect(subject).to eq(new_extensions_path)
      end
    end
  end

  describe '#extensions_suffix' do
    subject { db_module.extensions_suffix }

    it 'default is .ext.rb' do
      expect(subject).to eq('.ext.rb')
    end

    describe 'with #extensions_suffix=' do
      let(:new_extensions_suffix) { '.db.rb' }

      before do
        db_module.extensions_suffix(new_extensions_suffix)
      end

      it 'set to new suffix' do
        expect(subject).to eq(new_extensions_suffix)
      end
    end
  end

  describe '#connection_options with a String' do
    it 'rejects a database.yml name, pointing at the Symbol form' do
      expect { db_module.connection_options('secondary') }
        .to raise_error(ArgumentError, /no longer accepts a database.yml name as a String \("secondary"\).*connection_options :secondary/)
      expect(db_module.connection_options).to be_nil
    end

    it 'accepts a URL' do
      db_module.connection_options('sqlite3:///tmp/example.db')
      expect(db_module.connection_options).to eq('sqlite3:///tmp/example.db')
    end
  end

  describe '#connection_options with a database configuration name as a Symbol' do
    let(:original_configurations) { ActiveRecord::Base.configurations.configurations }
    let(:env) { ActiveRecord::ConnectionHandling::DEFAULT_ENV.call }
    let(:secondary) { create_test_database('CREATE TABLE widgets (id INTEGER PRIMARY KEY);') }

    before do
      original_configurations
      ActiveRecord::Base.configurations = { env => { 'secondary' => secondary.transform_keys(&:to_s) } }
    end

    after { ActiveRecord::Base.configurations = original_configurations }

    it 'passes the Symbol to establish_connection, which resolves it without a warning' do
      expect do
        db_module.connection_options(:secondary)
        db_module.create_models!
      end.not_to output.to_stderr
      expect(db_module.connection_options).to eq(:secondary)
      expect(db_module.database.models.map(&:table_name)).to eq(['widgets'])
    end
  end

  describe '#skip_tables' do
    subject { db_module.skip_tables }

    it 'defautl is empty array' do
      expect(subject).to eq([])
    end

    describe 'with #skip_tables=' do
      let(:tables_to_skip) { %w[foo bar] }

      before do
        db_module.skip_tables(tables_to_skip)
      end

      it 'equal to tables to skip' do
        expect(subject).to eq(tables_to_skip)
      end
    end

    describe '#skip_table' do
      let(:tables_to_skip) { %w[foo bar] }

      before do
        tables_to_skip.each do |table|
          db_module.skip_table table
        end
      end

      it 'equal to tables to skip' do
        expect(subject).to eq(tables_to_skip)
      end
    end
  end

  describe '#relationships' do
    subject { db_module.relationships }

    it 'defautl to empty hash' do
      expect(subject).to eq({})
    end

    describe 'with #relationships=' do
      let(:new_relationships) do
        {
          'users' => {
            'current_user_id' => 'current_user',
            'super_user_id' => 'super_user'
          }
        }
      end

      before do
        db_module.relationships(new_relationships)
      end

      it 'equal to new relationships' do
        expect(subject).to eq(new_relationships)
      end
    end

    describe 'with #foreign_key' do
      let(:new_relationships) do
        {
          'users' => {
            'current_user_id' => 'current_user',
            'super_user_id' => 'super_user'
          }
        }
      end

      before do
        new_relationships.each do |table_name, foreign_keys|
          foreign_keys.each do |foreign_key, relationship_name|
            db_module.foreign_key(table_name, foreign_key, relationship_name)
          end
        end
      end

      it 'equal to new relationships' do
        expect(subject).to eq(new_relationships)
      end
    end
  end

  describe '#table_class_name' do
    subject { db_module.table_class_names }

    it 'defaults to empty' do
      expect(subject).to eq({})
    end

    describe 'with a table class name' do
      before do
        db_module.table_class_name 'statuses', 'StatusList'
      end

      it 'stores the class name by table' do
        expect(subject).to eq('statuses' => 'StatusList')
      end
    end
  end

  describe '#create_models! with table class names' do
    before do
      db_module.connection_options(create_test_database(<<~SQL))
        CREATE TABLE status (id INTEGER PRIMARY KEY);
        CREATE TABLE statuses (id INTEGER PRIMARY KEY);
      SQL
      db_module.table_class_name 'statuses', 'StatusList'
      db_module.create_models!
    end

    it 'uses the table class name' do
      expect(base_module.const_get(:StatusList).table_name).to eq('statuses')
    end
  end

  describe '#database' do
    subject { db_module.database }

    it 'defaults to nil' do
      expect(subject).to be_nil
    end
  end

  describe '#create_models!' do
    subject { db_module.create_models! }

    before do
      db_module.connection_options DB_CONFIG
      db_module.extensions_path 'spec/support/db/extensions'
      db_module.foreign_key('websites', 'company_website_id', 'company_website')
      db_module.skip_table 'tmp_load_data_table'
      subject
    end

    it 'user model exists' do
      expect(base_module.const_defined?('User')).to be(true)
    end

    it 'user model is extended' do
      expect(base_module.const_get('User').method_defined?(:my_middle_name)).to be(true)
    end

    it 'expects #database to be set' do
      expect(base_module.database.nil?).to be(false)
    end
  end
end
