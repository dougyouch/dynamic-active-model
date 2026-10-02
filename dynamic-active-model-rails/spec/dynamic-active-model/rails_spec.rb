# frozen_string_literal: true

RSpec.describe DynamicActiveModel::Rails do
  describe '.configure' do
    it 'registers each database once' do
      expect { described_class.configure { |config| config } }.not_to(change { described_class.loaders.size })
      expect(described_class.loaders.map { |loader| loader.definition.module_name }).to eq(%w[AppDB CarsDB])
    end
  end

  describe '.eager_load!' do
    it 'builds every database' do
      described_class.eager_load!
      expect(described_class.loaders).to all(be_loaded)
    end
  end

  describe '.reset!' do
    it 'resets every database' do
      described_class.eager_load!
      described_class.reset!
      expect(described_class.loaders).to all(satisfy { |loader| !loader.loaded? })
    end
  end

  describe 'model behavior' do
    it 'shares ApplicationRecord connection for databases without a connection' do
      expect(AppDB::User.connection_pool).to equal(ApplicationRecord.connection_pool)
    end

    it 'connects to the database.yml entry for databases with a connection' do
      expect(CarsDB::Car.connection_pool).not_to equal(ApplicationRecord.connection_pool)
      expect(CarsDB::Car.connection_pool.db_config.name).to eq('cars')
    end

    it 'applies extension files' do
      expect(AppDB::User.new(first_name: 'Ada', last_name: 'Lovelace').full_name).to eq('Ada Lovelace')
    end

    it 'skips tables from the configure block' do
      expect(AppDB.models.map(&:table_name)).not_to include('audit_logs')
    end

    it 'builds relationships' do
      expect(CarsDB::Car.reflect_on_association(:make).klass).to eq(CarsDB::Make)
    end
  end
end
