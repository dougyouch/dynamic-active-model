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
        expect(subject).to  eq(tables_to_skip)
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
