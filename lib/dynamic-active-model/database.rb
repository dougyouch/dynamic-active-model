# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::Database iterates over the tables of a
  #  database and create ActiveRecord models
  class Database
    attr_reader :table_class_names,
                :factory,
                :models

    def initialize(base_module, connection_options, base_class_name = nil)
      @factory = Factory.new(base_module, connection_options, base_class_name)
      @table_class_names = {}
      @skip_tables = []
      @skip_table_matchers = []
      @models = []
    end

    def skip_table(table)
      if table.is_a?(Regexp)
        @skip_table_matchers << table
      else
        @skip_tables << table.to_s
      end
    end

    def table_class_name(table_name, class_name)
      @table_class_names[table_name.to_s] = class_name
    end

    def create_models!
      @factory.base_class.connection.tables.each do |table_name|
        next if skip_table?(table_name)

        @models << @factory.create(table_name, @table_class_names[table_name])
      end
    end

    def skip_tables
      @skip_tables + @skip_table_matchers
    end

    private

    def skip_table?(table_name)
      @skip_tables.include?(table_name) ||
        @skip_table_matchers.any? { |r| r.match(table_name) }
    end
  end
end
