# frozen_string_literal: true

DynamicActiveModel::Rails.configure do |config|
  config.add_database :app do |db|
    db.skip_tables 'audit_*'
  end
  config.add_database :cars, :cars
end

# runs after every build of AppDB's models, with the Database as self
ActiveSupport.on_load(:app_db) do
  get_model!(:users).define_singleton_method(:load_hook_ran?) { true }
end
