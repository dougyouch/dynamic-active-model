# frozen_string_literal: true

require 'tmpdir'

# Adapter-neutral access to the specs' database server, chosen with
# DATABASE_ADAPTER (sqlite3, the default, postgresql or trilogy for MySQL).
# DATABASE_HOST/PORT/USERNAME/PASSWORD point at a server.
module TestDatabase
  ADAPTER = ENV.fetch('DATABASE_ADAPTER', 'sqlite3')
  DEFAULT_USERNAMES = { 'postgresql' => 'postgres', 'trilogy' => 'root' }.freeze

  # Short-lived connections for creating databases and running setup SQL
  class Connection < ActiveRecord::Base
    self.abstract_class = true
  end

  module_function

  # @param name [String] Database name
  # @return [Hash] Connection config for that database
  def config(name)
    return { adapter: 'sqlite3', database: File.join(Dir.tmpdir, "#{name}.sqlite3") } if ADAPTER == 'sqlite3'

    server.merge(adapter: ADAPTER, database: name)
  end

  # Drops and creates an empty database
  # @param name [String]
  # @return [Hash] Its connection config
  def recreate(name)
    drop(name)
    with_server { |connection| connection.create_database(name) } unless ADAPTER == 'sqlite3'
    config(name)
  end

  # @param name [String]
  # @return [void]
  def drop(name)
    return FileUtils.rm_f(Dir.glob("#{config(name)[:database]}*")) if ADAPTER == 'sqlite3'

    with_server { |connection| connection.drop_database(name) }
  end

  # Runs ;-separated SQL statements in a database
  # @param config [Hash]
  # @param sql [String]
  # @return [void]
  def execute(config, sql)
    with_connection(config) do |connection|
      sql.split(';').map(&:strip).reject(&:empty?).each { |statement| connection.execute(statement) }
    end
  end

  # @return [Hash] Server settings from the environment
  def server
    {
      host: ENV.fetch('DATABASE_HOST', '127.0.0.1'),
      port: ENV['DATABASE_PORT']&.to_i,
      username: ENV.fetch('DATABASE_USERNAME', DEFAULT_USERNAMES[ADAPTER]),
      password: ENV.fetch('DATABASE_PASSWORD', nil)
    }.compact
  end

  # Yields a connection to the server's maintenance database
  def with_server(&)
    with_connection(server.merge(adapter: ADAPTER, database: ADAPTER == 'postgresql' ? 'postgres' : nil).compact, &)
  end

  def with_connection(config, &)
    Connection.establish_connection(config)
    Connection.with_connection(&)
  ensure
    Connection.remove_connection
  end
end
