# frozen_string_literal: true

module DynamicActiveModel
  # The ForeignKey class manages foreign key relationships for a model.
  # It provides functionality for:
  # - Tracking foreign key columns
  # - Generating standard foreign key names
  # - Managing custom relationship names
  # - Configuring the foreign key suffix
  #
  # @example Basic Usage
  #   model = DB::User
  #   fk = DynamicActiveModel::ForeignKey.new(model)
  #   fk.add('manager_id', 'manager')
  #
  # @example Custom Suffix
  #   DynamicActiveModel::ForeignKey.id_suffix = '_ref'
  class ForeignKey
    # @return [Class] The model this foreign key belongs to
    attr_reader :model
    
    # @return [Hash] Mapping of foreign key columns to relationship names
    attr_reader :keys

    # Default suffix used for foreign key columns
    DEFAULT_ID_SUFFIX = '_id'

    # Gets the current foreign key suffix
    # @return [String] The suffix used for foreign key columns
    def self.id_suffix
      @id_suffix || DEFAULT_ID_SUFFIX
    end

    # Sets a custom foreign key suffix
    # @param val [String] The new suffix to use
    def self.id_suffix=(val)
      @id_suffix = val
    end

    # Initializes a new ForeignKey instance
    # @param model [Class] The model to track foreign keys for
    def initialize(model)
      @model = model
      @keys = {}
      add(generate_foreign_key(model.table_name))
    end

    # Adds a foreign key to track
    # @param key [String] The foreign key column name
    # @param relationship_name [String, nil] Optional custom name for the relationship
    def add(key, relationship_name = nil)
      @keys[key] = relationship_name || model.table_name.underscore
    end

    # Generates a standard foreign key name from a table name
    # @param table_name [String] The name of the referenced table
    # @return [String] The generated foreign key column name
    def generate_foreign_key(table_name)
      table_name.underscore.singularize + self.class.id_suffix
    end
  end
end
