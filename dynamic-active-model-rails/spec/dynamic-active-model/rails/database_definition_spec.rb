# frozen_string_literal: true

RSpec.describe DynamicActiveModel::Rails::DatabaseDefinition do
  subject(:definition) { described_class.new(name, connection, **options) }

  let(:name) { :cars }
  let(:connection) { nil }
  let(:options) { {} }

  describe '#module_name' do
    it 'appends DB to the name' do
      expect(definition.module_name).to eq('CarsDB')
    end

    context 'when the name already ends in _db' do
      let(:name) { :grant_db }

      it 'does not double the suffix' do
        expect(definition.module_name).to eq('GrantDB')
      end
    end

    context 'when the name is a camelized string' do
      let(:name) { 'GrantDB' }

      it 'normalizes it' do
        expect(definition.module_name).to eq('GrantDB')
      end
    end

    context 'with a module_name override' do
      let(:options) { { module_name: 'Inventory' } }

      it 'uses the override' do
        expect(definition.module_name).to eq('Inventory')
      end
    end
  end

  describe '#folder' do
    it 'underscores the module name' do
      expect(definition.folder).to eq('cars_db')
    end

    context 'with a module_name override' do
      let(:options) { { module_name: 'Inventory' } }

      it 'follows the override' do
        expect(definition.folder).to eq('inventory')
      end
    end
  end

  describe '#load_hook' do
    it 'is named after the folder' do
      expect(definition.load_hook).to eq(:cars_db)
    end
  end

  describe '#extensions_path' do
    it 'is the folder under app/models' do
      expect(definition.extensions_path(Pathname.new('/app'))).to eq('/app/app/models/cars_db')
    end
  end

  describe '#connection' do
    let(:connection) { :cars }

    it 'keeps the connection as given' do
      expect(definition.connection).to eq(:cars)
    end
  end

  describe '#parent_class_name' do
    it 'defaults to ApplicationRecord' do
      expect(definition.parent_class_name).to eq('ApplicationRecord')
    end

    context 'with a parent_class option' do
      let(:options) { { parent_class: ActiveRecord::Base } }

      it 'stores the name so the class can be resolved after a reload' do
        expect(definition.parent_class_name).to eq('ActiveRecord::Base')
      end
    end
  end

  describe '#skip_tables' do
    it 'accumulates tables and arrays of tables' do
      definition.skip_tables 'legacy_*', /^tmp_/
      definition.skip_tables %w[a b]
      expect(definition.skipped_tables).to eq(['legacy_*', /^tmp_/, 'a', 'b'])
    end
  end

  describe '#foreign_key' do
    it 'records the relationship name by table and column' do
      definition.foreign_key :cars, :owner_id, :owner
      expect(definition.relationships).to eq('cars' => { 'owner_id' => 'owner' })
    end
  end

  describe '#table_class_name' do
    it 'records the class name by table' do
      definition.table_class_name :status, 'StatusCode'
      expect(definition.table_class_names).to eq('status' => 'StatusCode')
    end
  end
end
