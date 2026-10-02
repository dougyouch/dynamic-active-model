# frozen_string_literal: true

require 'generators/dynamic_active_model/install/install_generator'
require 'generators/dynamic_active_model/database/database_generator'

RSpec.describe DynamicActiveModel::Generators::DatabaseGenerator, type: :generator do
  let(:initializer) { generated('config/initializers/dynamic_active_model.rb') }

  it 'is found by rails generate' do
    expect(Rails::Generators.find_by_namespace('dynamic_active_model:database')).to eq(described_class)
  end

  context 'with an installed initializer' do
    before { run_generator(DynamicActiveModel::Generators::InstallGenerator, ['grant_db']) }

    it 'adds the database inside the configure block' do
      run_generator(described_class, %w[inventory --connection cars])
      expect(initializer).to match(/:grant_db\n.*\n  config.add_database :inventory, :cars\nend\n/m)
      expect(valid_ruby?(initializer)).to be(true)
      expect(generated?('app/models/inventory_db/.keep')).to be(true)
    end

    it 'refuses a namespace the app already declares' do
      expect { run_generator(described_class, ['cars']) }.to raise_error(Thor::Error, 'CarsDB is already declared')
    end
  end

  it 'requires the initializer' do
    expect { run_generator(described_class, ['inventory']) }
      .to raise_error(Thor::Error, /run rails g dynamic_active_model:install first/)
  end
end
