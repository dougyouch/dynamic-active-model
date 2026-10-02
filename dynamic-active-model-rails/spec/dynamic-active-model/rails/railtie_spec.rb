# frozen_string_literal: true

RSpec.describe DynamicActiveModel::Rails::Railtie do
  it 'registers DynamicActiveModel::Rails for eager loading' do
    expect(Rails.application.config.eager_load_namespaces).to include(DynamicActiveModel::Rails)
  end

  it 'watches db/ so schema changes trigger a reload' do
    expect(Rails.application.config.watchable_dirs).to include(Rails.root.join('db').to_s => %i[rb sql])
  end

  it 'maps database folders to DB namespaces in the autoloader only' do
    expect(Rails.autoloaders.main.inflector.camelize('cars_db', nil)).to eq('CarsDB')
    expect('cars_db'.camelize).to eq('CarsDb')
  end

  it 'eager loads app/models without autoloading .ext.rb files' do
    expect { Rails.autoloaders.main.eager_load }.not_to raise_error
    expect(CarsDB::Search.for_make('Honda').to_a).to eq([])
  end

  describe 'code reloading' do
    it 'rebuilds models against the reloaded ApplicationRecord' do
      user = AppDB::User
      Rails.application.reloader.reload!
      expect(AppDB.dynamic_active_model_loader.loaded?).to be(false)
      expect(AppDB::User).not_to equal(user)
      expect(AppDB::User.ancestors).to include(ApplicationRecord)
    end
  end
end
