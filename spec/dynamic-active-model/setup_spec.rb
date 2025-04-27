# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Setup do
  include_context 'database'

  let(:db_module) do
    base_module.include DynamicActiveModel::Setup
    base_module
  end

  context '#connection_options' do
    subject { db_module.connection_options }

    it 'default is nil' do
      expect(subject).to eq(nil)
    end

    describe 'with #connection_options=' do
      before(:each) do
        db_module.connection_options = DB_CONFIG
      end

      it 'set to DB_CONFIG' do
        expect(subject).to eq(DB_CONFIG)
      end
    end

    describe 'with #set_connection_options' do
      before(:each) do
        db_module.set_connection_options DB_CONFIG
      end

      it 'set to DB_CONFIG' do
        expect(subject).to eq(DB_CONFIG)
      end
    end
  end

  context '#extensions_path' do
    subject { db_module.extensions_path }

    it 'default is nil' do
      expect(subject).to eq(nil)
    end

    describe 'with #extensions_path=' do
      let(:new_extensions_path) { 'lib/db/extensions' }
      before(:each) do
        db_module.extensions_path = new_extensions_path
      end

      it 'set to new path' do
        expect(subject).to eq(new_extensions_path)
      end
    end

    describe 'with #set_extensions_path=' do
      let(:new_extensions_path) { 'lib/db/extensions' }
      before(:each) do
        db_module.set_extensions_path new_extensions_path
      end

      it 'set to new path' do
        expect(subject).to eq(new_extensions_path)
      end
    end
  end

  context '#skip_tables' do
    subject { db_module.skip_tables }

    it 'defautl is empty array' do
      expect(subject).to eq([])
    end

    describe 'with #skip_tables=' do
      let(:tables_to_skip) { ['foo', 'bar'] }
      before(:each) do
        db_module.skip_tables = tables_to_skip
      end

      it 'equal to tables to skip' do
        expect(subject).to  eq(tables_to_skip)
      end
    end

    describe 'with #set_skip_tables' do
      let(:tables_to_skip) { ['foo', 'bar'] }
      before(:each) do
        db_module.set_skip_tables tables_to_skip
      end

      it 'equal to tables to skip' do
        expect(subject).to  eq(tables_to_skip)
      end
    end

    describe '#skip_table' do
      let(:tables_to_skip) { ['foo', 'bar'] }
      before(:each) do
        tables_to_skip.each do |table|
          db_module.skip_table table
        end
      end

      it 'equal to tables to skip' do
        expect(subject).to  eq(tables_to_skip)
      end
    end
  end

  context '#relationships' do
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
      before(:each) do
        db_module.relationships = new_relationships
      end

      it 'equal to new relationships' do
        expect(subject).to eq(new_relationships)
      end
    end

    describe 'with #set_relationships' do
      let(:new_relationships) do
        {
          'users' => {
            'current_user_id' => 'current_user',
            'super_user_id' => 'super_user'
          }
        }
      end
      before(:each) do
        db_module.set_relationships new_relationships
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
      before(:each) do
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

  context '#database' do
    subject { db_module.database }

    it 'defaults to nil' do
      expect(subject).to eq(nil)
    end
  end

  context '#create_models!' do
    subject { db_module.create_models! }
    before(:each) do
      db_module.connection_options = DB_CONFIG
      db_module.extensions_path = 'spec/support/db/extensions'
      db_module.foreign_key('websites', 'company_website_id', 'company_website')
      db_module.skip_table 'tmp_load_data_table'
      subject()
    end

    it 'user model exists' do
      expect(base_module.const_defined?('User')).to eq(true)
    end

    it 'user model is extended' do
      expect(base_module.const_get('User').method_defined?(:my_middle_name)).to eq(true)
    end

    it 'expects #database to be set' do
      expect(base_module.database.nil?).to eq(false)
    end
  end
end
