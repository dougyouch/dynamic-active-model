# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'securerandom'
require 'active_record'
require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.start do
  enable_coverage :branch
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])
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

DB_FILE = 'spec/test.db'
DB_CONFIG = {
  adapter: 'sqlite3',
  database: DB_FILE
}.freeze
File.unlink(DB_FILE) if File.exist?(DB_FILE)
ActiveRecord::Base.establish_connection(DB_CONFIG)
ActiveRecord::Schema.verbose = false
require 'support/db/schema'

# rubocop:disable Metrics/BlockLength
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
# rubocop:enable Metrics/BlockLength

def get_association(model, name)
  model.reflect_on_all_associations.detect { |assoc| assoc.name == name }
end

def has_association?(model, name)
  get_association(model, name) != nil
end
