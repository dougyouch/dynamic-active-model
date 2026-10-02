# frozen_string_literal: true

DynamicActiveModel::Rails.configure do |config|
  config.add_database :app do |db|
    db.skip_tables 'audit_*'
  end
  config.add_database :cars, :cars
  # the cars database again, with a read replica
  config.add_database :fleet, connects_to: { writing: :cars, reading: :cars_replica }
end

# runs after every build of AppDB's models, with the Database as self
ActiveSupport.on_load(:app_db) do
  get_model!(:users).define_singleton_method(:load_hook_ran?) { true }
end
