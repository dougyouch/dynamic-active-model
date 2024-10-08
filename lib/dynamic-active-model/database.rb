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
      @include_tables = []
      @include_table_matchers = []
      @models = []
    end

    def skip_table(table)
      if table.is_a?(Regexp)
        @skip_table_matchers << table
      else
        @skip_tables << table.to_s
      end
    end

    def skip_tables(tables)
      tables.each { |table| skip_table(table) }
    end

    def include_table(table)
      if table.is_a?(Regexp)
        @include_table_matchers << table
      else
        @include_tables << table.to_s
      end
    end

    def include_tables(tables)
      tables.each { |table| include_table(table) }
    end

    def table_class_name(table_name, class_name)
      @table_class_names[table_name.to_s] = class_name
    end

    def create_models!
      @factory.base_class.connection.tables.each do |table_name|
        next if skip_table?(table_name)
        next unless include_table?(table_name)

        @models << @factory.create(table_name, @table_class_names[table_name])
      end
    end

    def skipped_tables
      @skip_tables + @skip_table_matchers
    end

    def included_tables
      @include_tables + @include_table_matchers
    end

    def disable_standard_table_inheritance!
      models.each do |model|
        model.inheritance_column = :_type_disabled if model.attribute_names.include?('type')
      end
    end
    alias disable_sti! disable_standard_table_inheritance!

    def get_model(table_name)
      table_name = table_name.to_s
      models.detect { |model| model.table_name == table_name }
    end

    def get_model!(table_name)
      model = get_model(table_name)
      return model if model

      raise ::DynamicActiveModel::ModelNotFound.new("no model found for table #{table_name}")
    end

    def update_model(table_name, file = nil, &block)
      model = get_model!(table_name)
      model.instance_eval(File.read(file)) if file
      model.class_eval(&block) if block
      model
    end

    def update_all_models(base_dir, ext='.ext.rb')
      Dir.glob("#{base_dir}/*#{ext}") do |file|
        next unless File.file?(file)

        table_name = File.basename(file).split('.', 2).first
        update_model(table_name, file)
      end
    end

    private

    def skip_table?(table_name)
      @skip_tables.include?(table_name.to_s) ||
        @skip_table_matchers.any? { |r| r.match(table_name) }
    end

    def include_table?(table_name)
      (@include_tables.empty? && @include_table_matchers.empty?) ||
        @include_tables.include?(table_name) ||
        @include_table_matchers.any? { |r| r.match(table_name) }
    end
  end
end
