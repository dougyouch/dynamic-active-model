# frozen_string_literal: true

require 'generators/dynamic_active_model/install/install_generator'

RSpec.describe DynamicActiveModel::Generators::InstallGenerator, type: :generator do
  let(:initializer) { generated('config/initializers/dynamic_active_model.rb') }

  it 'is found by rails generate' do
    expect(Rails::Generators.find_by_namespace('dynamic_active_model:install')).to eq(described_class)
  end

  context 'without arguments' do
    before { run_generator(described_class, []) }

    it 'declares the db database' do
      expect(initializer).to include('config.add_database :db')
      expect(initializer).to include('ActiveSupport.on_load(:db)')
      expect(valid_ruby?(initializer)).to be(true)
    end

    it 'creates the models folder' do
      expect(generated?('app/models/db/.keep')).to be(true)
    end
  end

  context 'with a name and connection' do
    let!(:output) { run_generator(described_class, %w[cars --connection cars]) }

    it 'declares that database' do
      expect(initializer).to include('config.add_database :cars, :cars')
      expect(initializer).to include("CarsDB's models")
      expect(initializer).to include('ActiveSupport.on_load(:cars_db)')
      expect(generated?('app/models/cars_db/.keep')).to be(true)
    end

    it 'does not warn about a connection database.yml has' do
      expect(output).not_to include('warning')
    end
  end

  context 'with a connection database.yml lacks' do
    it 'warns' do
      expect(run_generator(described_class, %w[cars --connection nope]))
        .to include('config/database.yml has no nope entry for test')
    end
  end
end
