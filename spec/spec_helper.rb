# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'fileutils'
require 'securerandom'
require 'active_record'
require 'simplecov'

SimpleCov.start do
  enable_coverage :branch

  cover 'lib/**/*.rb'
  # loaded by the gemspec before SimpleCov starts, so it would always show as missed
  skip 'lib/dynamic-active-model/version.rb'
end

begin
  Bundler.require(:default, :spec)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)
require 'dynamic-active-model'

require 'support/test_database'
require 'support/test_database_helpers'
require 'support/foreign_key_constraints_schema'

DB_CONFIG = TestDatabase.recreate('dynamic_active_model_test').freeze
ActiveRecord::Base.establish_connection(DB_CONFIG)
ActiveRecord::Schema.verbose = false
require 'support/db/schema'

RSpec.configure do |config|
  # Every example builds its own abstract base class with its own connection pool;
  # close them so the suite doesn't run out of file descriptors. Registered after
  # support/test_database_helpers so it runs before that file's cleanup (after hooks run in
  # reverse); PostgreSQL won't drop a database with open connections.
  config.after { ActiveRecord::Base.connection_handler.connection_pool_list.each(&:disconnect!) }
end

RSpec.shared_context 'database' do
  let(:base_module_name) { "Module#{SecureRandom.hex(8)}" }
  let(:base_module) do
    Object.const_set(base_module_name, Module.new)
    Object.const_get(base_module_name)
  end
  let(:connection_options) { DB_CONFIG }
  let(:base_class_name) { nil }
  let(:base_class) { nil }
  let(:database) do
    DynamicActiveModel::Database.new(
      base_module,
      connection_options,
      base_class_name
    ).tap do |db|
      db.factory.base_class = base_class
    end
  end
  let(:factory) do
    DynamicActiveModel::Factory.new(
      base_module,
      connection_options,
      base_class_name
    ).tap do |fact|
      fact.base_class = base_class
    end
  end
  let(:foreign_key) { DynamicActiveModel::ForeignKey.new(factory.create('users')) }
  let(:relations) do
    database.create_models! if database.models.empty?
    DynamicActiveModel::Associations.new(database)
  end
end

def get_association(model, name)
  model.reflect_on_all_associations.detect { |assoc| assoc.name == name }
end

def has_association?(model, name)
  get_association(model, name) != nil
end
