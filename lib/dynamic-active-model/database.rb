# frozen_string_literal: true

module DynamicActiveModel
  class Database
    attr_reader :table_class_names

    def initialize(base_module, connection_options, base_class_name=nil)
      @factory = Factory.new(base_module, connection_options, base_class_name)
      @table_class_names = {}
      @skip_tables = []
      @skip_table_matchers = []
    end

    def skip_table(v)
      if v.is_a?(Regexp)
        @skip_table_matchers << v
      else
        @skip_tables << v.to_s
      end
    end

    def table_class_name(table_name, class_name)
      @table_class_names[table_name.to_s] = class_name
    end

    def create_models!
      @factory.base_class.connection.tables.each do |table_name|
        next if skip_table?(table_name)
        @factory.create(table_name, @table_class_names[table_name])
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
