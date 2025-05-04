# frozen_string_literal: true

module DynamicActiveModel
  # The Factory class is responsible for creating ActiveRecord model classes
  # from database tables. It handles:
  # - Base class creation and connection setup
  # - Model class generation with proper naming
  # - Table name assignment
  # - Safety patches for dangerous attributes
  #
  # @example Basic Usage
  #   factory = DynamicActiveModel::Factory.new(DB, database_config)
  #   model = factory.create('users')
  #
  # @example With Custom Class Name
  #   factory = DynamicActiveModel::Factory.new(DB, database_config)
  #   model = factory.create('users', 'CustomUser')
  class Factory
    # @return [Class] The base class for all generated models
    attr_writer :base_class

    # Initializes a new Factory instance
    # @param base_module [Module] The namespace for created models
    # @param connection_options [Hash] Database connection options
    # @param base_class_name [Symbol, nil] Optional name for the base class
    def initialize(base_module, connection_options, base_class_name = nil)
      @base_module = base_module
      @connection_options = connection_options
      @base_class_name = base_class_name || :DynamicAbstractBase
    end

    # Creates a new model class for a table if it doesn't exist
    # @param table_name [String] Name of the database table
    # @param class_name [String, nil] Optional custom class name
    # @return [Class] The model class
    def create(table_name, class_name = nil)
      class_name ||= generate_class_name(table_name)
      create!(table_name, class_name) unless @base_module.const_defined?(class_name)
      @base_module.const_get(class_name)
    end

    # Creates a new model class for a table, overwriting if it exists
    # @param table_name [String] Name of the database table
    # @param class_name [String] Name for the model class
    # @return [Class] The model class
    def create!(table_name, class_name)
      kls = Class.new(base_class) do
        self.table_name = table_name
        include DynamicActiveModel::DangerousAttributesPatch
      end
      @base_module.const_set(class_name, kls)
      @base_module.const_get(class_name)
    end

    # Gets or creates the base class for all models
    # This method:
    # 1. Creates an abstract ActiveRecord::Base subclass if needed
    # 2. Establishes the database connection
    # 3. Returns the configured base class
    # @return [Class] The base class for all models
    def base_class
      @base_class ||=
        begin
          require 'active_record'

          unless @base_module.const_defined?(@base_class_name)
            new_base_class = Class.new(ActiveRecord::Base) do
              self.abstract_class = true
            end
            @base_module.const_set(@base_class_name, new_base_class)
          end

          @base_module.const_get(@base_class_name).tap do |kls|
            kls.establish_connection @connection_options
          end
        end
    end

    # Generates a valid Ruby class name from a table name
    # @param table_name [String] Name of the database table
    # @return [String] A valid Ruby class name
    def generate_class_name(table_name)
      class_name = table_name.classify
      return "N#{class_name}" if class_name =~ /\A\d/

      class_name
    end
  end
end
