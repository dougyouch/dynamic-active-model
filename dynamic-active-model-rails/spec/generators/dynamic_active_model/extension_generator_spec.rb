# frozen_string_literal: true

require 'generators/dynamic_active_model/extension/extension_generator'

RSpec.describe DynamicActiveModel::Generators::ExtensionGenerator, type: :generator do
  it 'is found by rails generate' do
    expect(Rails::Generators.find_by_namespace('dynamic_active_model:extension')).to eq(described_class)
  end

  it 'creates the extension file for a database name' do
    run_generator(described_class, %w[app users])
    extension = generated('app/models/app_db/users.ext.rb')
    expect(extension).to include('Extends AppDB::User (table users)')
    expect(extension).to include("update_model do\nend")
    expect(valid_ruby?(extension)).to be(true)
  end

  it 'accepts the namespace instead of the name' do
    run_generator(described_class, %w[CarsDB makes])
    expect(generated('app/models/cars_db/makes.ext.rb')).to include('CarsDB::Make')
  end

  it 'raises for a database the app does not declare' do
    expect { run_generator(described_class, %w[nope users]) }
      .to raise_error(Thor::Error, 'no database nope is declared (declared: AppDB, CarsDB, FleetDB)')
  end

  context 'with a custom extensions path, suffix and class name' do
    let(:legacy) do
      DynamicActiveModel::Rails::DatabaseDefinition.new(:legacy, extensions_path: 'lib/legacy', extensions_suffix: '.model.rb')
                                                   .tap { |db| db.table_class_name :status, 'StatusCode' }
    end

    before { allow(DynamicActiveModel::Rails.configuration).to receive(:definitions).and_return([legacy]) }

    it 'follows the database configuration' do
      run_generator(described_class, %w[legacy status])
      expect(generated('lib/legacy/status.model.rb')).to include('Extends LegacyDB::StatusCode (table status)')
    end
  end
end
