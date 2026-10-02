# frozen_string_literal: true

# FleetDB is declared with connects_to: { writing: :cars, reading: :cars_replica }
RSpec.describe 'connects_to databases' do # rubocop:disable RSpec/DescribeClass
  def pool_name
    FleetDB::Car.connection_pool.db_config.name
  end

  it 'writes through the writing role by default' do
    expect(pool_name).to eq('cars')
  end

  it 'reads through the reading role inside connected_to' do
    expect(FleetDB.connected_to(role: :reading) { pool_name }).to eq('cars_replica')
  end

  it 'prevents writes in the reading role' do
    FleetDB.connected_to(role: :reading) do
      expect { FleetDB::Make.create!(name: 'Honda') }.to raise_error(ActiveRecord::ReadOnlyError)
    end
  end

  it 'switches only this database' do
    FleetDB.connected_to(role: :reading) do
      expect(CarsDB::Car.connection_pool.db_config.name).to eq('cars')
    end
  end

  it 'reconnects after a reset' do
    FleetDB.database
    DynamicActiveModel::Rails.reset!
    expect(FleetDB.connected_to(role: :reading) { pool_name }).to eq('cars_replica')
  end

  describe 'namespace connected_to for other databases' do
    it 'switches the connection-owning class of a database with its own connection' do
      expect(CarsDB.dynamic_active_model_loader.connection_class).to eq(CarsDB::DynamicAbstractBase)
    end

    it "switches the parent class for a database sharing ApplicationRecord's connection" do
      expect(AppDB.dynamic_active_model_loader.connection_class).to eq(ApplicationRecord)
      expect(AppDB.connected_to(role: :writing) { AppDB::User.count }).to eq(0)
    end
  end
end
