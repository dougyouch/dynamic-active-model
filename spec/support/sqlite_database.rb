# frozen_string_literal: true

require 'tmpdir'

# Builds a throwaway SQLite database for specs whose schema can't live in the
# shared spec/support/db/schema.rb without changing every other spec's models.
module SqliteDatabase
  def create_sqlite_database(sql)
    file = File.join(Dir.tmpdir, "dynamic-active-model-#{SecureRandom.hex(8)}.db")
    SQLite3::Database.new(file) { |db| db.execute_batch(sql) }
    sqlite_database_files << file
    { adapter: 'sqlite3', database: file }
  end

  def sqlite_database_files
    @sqlite_database_files ||= []
  end
end

RSpec.configure do |config|
  config.include SqliteDatabase
  config.after { sqlite_database_files.each { |file| FileUtils.rm_f(Dir.glob("#{file}*")) } }
end
