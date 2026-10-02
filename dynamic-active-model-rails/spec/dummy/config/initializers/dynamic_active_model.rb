# frozen_string_literal: true

DynamicActiveModel::Rails.configure do |config|
  config.add_database :app do |db|
    db.skip_tables 'audit_*'
  end
  config.add_database :cars, :cars
end
