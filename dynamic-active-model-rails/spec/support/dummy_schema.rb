# frozen_string_literal: true

require 'sqlite3'

# Creates the dummy app's tables directly through SQLite so no ActiveRecord
# connection (or model) exists before the specs reference one.
module DummySchema
  PRIMARY = <<~SQL
    CREATE TABLE users (id INTEGER PRIMARY KEY, first_name TEXT, last_name TEXT);
    CREATE TABLE posts (id INTEGER PRIMARY KEY, user_id INTEGER, title TEXT);
    CREATE TABLE audit_logs (id INTEGER PRIMARY KEY, message TEXT);
  SQL

  CARS = <<~SQL
    CREATE TABLE makes (id INTEGER PRIMARY KEY, name TEXT);
    CREATE TABLE cars (id INTEGER PRIMARY KEY, make_id INTEGER, model TEXT);
  SQL

  module_function

  def create!
    execute(:primary, PRIMARY)
    execute(:cars, CARS)
  end

  # @param database [Symbol] :primary or :cars
  # @param sql [String]
  def execute(database, sql)
    SQLite3::Database.new(path(database)) { |db| db.execute_batch(sql) }
  end

  def path(database)
    Rails.root.join('tmp', "#{database}.sqlite3").to_s
  end
end
