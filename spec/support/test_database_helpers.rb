# frozen_string_literal: true

# Builds throwaway databases (on whichever adapter TestDatabase targets) for specs
# whose schema can't live in the shared spec/support/db/schema.rb without
# changing every other spec's models. Keep the SQL portable across adapters.
module TestDatabaseHelpers
  # @param sql [String] ;-separated statements to run in the new database
  # @return [Hash] Its connection config
  def create_test_database(sql)
    name = "dam_spec_#{SecureRandom.hex(6)}"
    test_database_names << name
    TestDatabase.recreate(name).tap { |config| TestDatabase.execute(config, sql) }
  end

  # @param config [Hash] A config from #create_test_database
  # @param sql [String]
  def execute_in_test_database(config, sql)
    TestDatabase.execute(config, sql)
  end

  def test_database_names
    @test_database_names ||= []
  end
end

RSpec.configure do |config|
  config.include TestDatabaseHelpers
  config.after { test_database_names.each { |name| TestDatabase.drop(name) } }
end
