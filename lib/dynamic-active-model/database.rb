# frozen_string_literal: true

module DynamicActiveModel
  # The Database class is responsible for connecting to a database and creating
  # ActiveRecord models from its tables. It provides functionality for:
  # - Table filtering (blacklist/whitelist)
  # - Model creation and management
  # - Model updates and extensions
  #
  # @example Basic Usage
  #   db = DynamicActiveModel::Database.new(DB, database_config)
  #   db.create_models!
  #
  # @example Table Filtering
  #   db.skip_table 'temporary_data'
  #   db.include_table 'users'
  #   db.create_models!
  #
  # @example Model Updates
  #   db.update_model(:users) do
  #     def full_name
  #       "#{first_name} #{last_name}"
  #     end
  #   end
  class Database
    # @return [Hash] Mapping of table names to custom class names
    attr_reader :table_class_names

    # @return [Factory] Factory instance used for model creation
    attr_reader :factory

    # @return [Array] List of created model classes
    attr_reader :models

    # Helper class for updating model definitions
    ModelUpdater = Struct.new(:model) do
      # Updates a model's definition with the provided block
      # @param block [Proc] Code to evaluate in the model's context
      def update_model(&block)
        model.class_eval(&block)
      end
    end

    # Initializes a new Database instance
    # @param base_module [Module] The namespace for created models
    # @param connection_options [Hash] Database connection options
    # @param base_class_name [String, nil] Optional base class name for models
    def initialize(base_module, connection_options, base_class_name = nil)
      @factory = Factory.new(base_module, connection_options, base_class_name)
      @table_class_names = {}
      @skip_tables = []
      @skip_table_matchers = []
      @include_tables = []
      @include_table_matchers = []
      @models = []
    end

    # Adds a table to the blacklist
    # @param table [String, Regexp] Table name or pattern to skip
    def skip_table(table)
      if table.is_a?(Regexp)
        @skip_table_matchers << table
      else
        @skip_tables << table.to_s
      end
    end

    # Adds multiple tables to the blacklist
    # @param tables [Array<String, Regexp>] Table names or patterns to skip
    def skip_tables(tables)
      tables.each { |table| skip_table(table) }
    end

    # Adds a table to the whitelist
    # @param table [String, Regexp] Table name or pattern to include
    def include_table(table)
      if table.is_a?(Regexp)
        @include_table_matchers << table
      else
        @include_tables << table.to_s
      end
    end

    # Adds multiple tables to the whitelist
    # @param tables [Array<String, Regexp>] Table names or patterns to include
    def include_tables(tables)
      tables.each { |table| include_table(table) }
    end

    # Sets a custom class name for a table
    # @param table_name [String] Name of the table
    # @param class_name [String] Custom class name to use
    def table_class_name(table_name, class_name)
      @table_class_names[table_name.to_s] = class_name
    end

    # Creates ActiveRecord models for all included tables
    # @return [Array] List of created model classes
    def create_models!
      @factory.base_class.connection.tables.each do |table_name|
        next if skip_table?(table_name)
        next unless include_table?(table_name)

        @models << @factory.create(table_name, @table_class_names[table_name])
      end
    end

    # @return [Array] List of all skipped tables and patterns
    def skipped_tables
      @skip_tables + @skip_table_matchers
    end

    # @return [Array] List of all included tables and patterns
    def included_tables
      @include_tables + @include_table_matchers
    end

    # Disables Single Table Inheritance (STI) for all models
    # @return [void]
    def disable_standard_table_inheritance!
      models.each do |model|
        model.inheritance_column = :_type_disabled if model.attribute_names.include?('type')
      end
    end
    alias disable_sti! disable_standard_table_inheritance!

    # Finds a model by table name
    # @param table_name [String] Name of the table
    # @return [Class, nil] The model class or nil if not found
    def get_model(table_name)
      table_name = table_name.to_s
      models.detect { |model| model.table_name == table_name }
    end

    # Finds a model by table name, raising an error if not found
    # @param table_name [String] Name of the table
    # @return [Class] The model class
    # @raise [ModelNotFound] If no model is found for the table
    def get_model!(table_name)
      model = get_model(table_name)
      return model if model

      raise ::DynamicActiveModel::ModelNotFound, "no model found for table #{table_name}"
    end

    # Updates a model's definition
    # @param table_name [String] Name of the table
    # @param file [String, nil] Path to a file containing model updates
    # @param block [Proc] Code to evaluate in the model's context
    # @return [Class] The updated model class
    def update_model(table_name, file = nil, &block)
      model = get_model!(table_name)
      ModelUpdater.new(model).instance_eval(File.read(file)) if file
      model.class_eval(&block) if block
      model
    end

    # Updates all models using extension files from a directory
    # @param base_dir [String] Directory containing extension files
    # @param ext [String] Extension for model update files
    # @return [void]
    def update_all_models(base_dir, ext = '.ext.rb')
      Dir.glob("#{base_dir}/*#{ext}") do |file|
        next unless File.file?(file)

        table_name = File.basename(file).split('.', 2).first
        update_model(table_name, file)
      end
    end

    private

    # Checks if a table should be skipped
    # @param table_name [String] Name of the table
    # @return [Boolean] Whether the table should be skipped
    def skip_table?(table_name)
      @skip_tables.include?(table_name.to_s) ||
        @skip_table_matchers.any? { |r| r.match(table_name) }
    end

    # Checks if a table should be included
    # @param table_name [String] Name of the table
    # @return [Boolean] Whether the table should be included
    def include_table?(table_name)
      (@include_tables.empty? && @include_table_matchers.empty?) ||
        @include_tables.include?(table_name) ||
        @include_table_matchers.any? { |r| r.match(table_name) }
    end
  end
end
