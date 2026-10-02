# frozen_string_literal: true

RSpec.describe DynamicActiveModel::Rails::Configuration do
  subject(:configuration) { described_class.new }

  describe '#add_database' do
    it 'returns and stores the definition' do
      definition = configuration.add_database(:cars, :cars)
      expect(configuration.definitions).to eq([definition])
      expect(definition.connection).to eq(:cars)
    end

    it 'yields the definition for table-level settings' do
      definition = configuration.add_database(:cars) { |db| db.skip_tables 'tmp_*' }
      expect(definition.skipped_tables).to eq(['tmp_*'])
    end

    it 'passes options through' do
      expect(configuration.add_database(:cars, module_name: 'Inventory').module_name).to eq('Inventory')
    end

    it 'raises when a namespace is declared twice' do
      configuration.add_database(:cars)
      expect { configuration.add_database(:cars_db) }.to raise_error(ArgumentError, /CarsDB is already declared/)
    end
  end
end
