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

    context 'when the name is just db' do
      let(:name) { :db }

      it 'is DB' do
        expect(definition.module_name).to eq('DB')
        expect(definition.folder).to eq('db')
      end
    end

    context 'when db is part of a word' do
      let(:name) { :mydb }

      it 'keeps the word and appends DB' do
        expect(definition.module_name).to eq('MydbDB')
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
    let(:root) { Pathname.new('/app') }

    it 'is the folder under app/models' do
      expect(definition.extensions_path(root)).to eq('/app/app/models/cars_db')
      expect(definition.custom_extensions_path?).to be(false)
    end

    context 'with a relative extensions_path option' do
      let(:options) { { extensions_path: 'lib/cars_ext' } }

      it 'resolves it against the app root' do
        expect(definition.extensions_path(root)).to eq('/app/lib/cars_ext')
        expect(definition.custom_extensions_path?).to be(true)
      end
    end

    context 'with an absolute extensions_path option' do
      let(:options) { { extensions_path: Pathname.new('/shared/cars_ext') } }

      it 'uses it as is' do
        expect(definition.extensions_path(root)).to eq('/shared/cars_ext')
      end
    end
  end

  describe '#extensions_suffix' do
    it 'defaults to .ext.rb' do
      expect(definition.extensions_suffix).to eq('.ext.rb')
    end

    context 'with an extensions_suffix option' do
      let(:options) { { extensions_suffix: '.model.rb' } }

      it 'uses the option' do
        expect(definition.extensions_suffix).to eq('.model.rb')
      end
    end
  end

  describe '#include_tables' do
    it 'accumulates tables and arrays of tables' do
      definition.include_tables 'cars', /^make/
      definition.include_tables %w[owners]
      expect(definition.included_tables).to eq(['cars', /^make/, 'owners'])
    end
  end

  describe '#connection' do
    let(:connection) { :cars }

    it 'keeps the connection as given' do
      expect(definition.connection).to eq(:cars)
    end
  end

  describe '#connects_to' do
    it 'defaults to nil' do
      expect(definition.connects_to).to be_nil
    end

    context 'with roles' do
      let(:options) { { connects_to: { writing: :cars, reading: :cars_replica } } }

      it 'wraps them as the database: argument' do
        expect(definition.connects_to).to eq(database: { writing: :cars, reading: :cars_replica })
      end
    end

    context "with connects_to's own arguments" do
      let(:options) { { connects_to: { shards: { one: { writing: :cars } } } } }

      it 'passes them through' do
        expect(definition.connects_to).to eq(shards: { one: { writing: :cars } })
      end
    end

    context 'with a connection as well' do
      let(:connection) { :cars }
      let(:options) { { connects_to: { writing: :cars } } }

      it 'raises' do
        expect { definition }.to raise_error(ArgumentError, /either a connection or connects_to/)
      end
    end
  end

  describe '#foreign_key_constraints' do
    it 'defaults to false' do
      expect(definition.foreign_key_constraints).to be(false)
    end

    context 'when enabled' do
      let(:options) { { foreign_key_constraints: true } }

      it 'is true' do
        expect(definition.foreign_key_constraints).to be(true)
      end
    end
  end

  describe '#has_many_through' do
    it 'defaults to false' do
      expect(definition.has_many_through).to be(false)
    end

    context 'when enabled' do
      let(:options) { { has_many_through: true } }

      it 'is true' do
        expect(definition.has_many_through).to be(true)
      end
    end
  end

  describe '#own_connection?' do
    it 'is false when sharing the parent class connection' do
      expect(definition.own_connection?).to be(false)
    end

    context 'with a connection' do
      let(:connection) { :cars }

      it 'is true' do
        expect(definition.own_connection?).to be(true)
      end
    end

    context 'with connects_to' do
      let(:options) { { connects_to: { writing: :cars } } }

      it 'is true' do
        expect(definition.own_connection?).to be(true)
      end
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
