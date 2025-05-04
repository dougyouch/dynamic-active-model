# frozen_string_literal: true

module DynamicActiveModel
  # The Explorer module provides a high-level interface for automatically discovering
  # and setting up ActiveRecord models and their relationships from a database schema.
  # It combines the functionality of Database and Associations classes into a simple
  # one-call interface.
  #
  # @example Basic Usage
  #   module DB; end
  #   DynamicActiveModel::Explorer.explore(DB, database_config)
  #
  # @example With Table Filtering
  #   skip_tables = ['temporary_data', 'audit_logs']
  #   DynamicActiveModel::Explorer.explore(DB, database_config, skip_tables)
  #
  # @example With Custom Relationships
  #   relationships = {
  #     'users' => {
  #       'manager_id' => 'manager',
  #       'department_id' => 'department'
  #     }
  #   }
  #   DynamicActiveModel::Explorer.explore(DB, database_config, [], relationships)
  module Explorer
    # Creates models and sets up relationships in a single call
    # @param base_module [Module] The namespace for created models
    # @param connection_options [Hash] Database connection options
    # @param skip_tables [Array<String, Regexp>] Tables to exclude from model creation
    # @param relationships [Hash] Custom foreign key relationships to add
    # @return [Database] The configured database instance
    def self.explore(base_module, connection_options, skip_tables = [], relationships = {})
      database = create_models!(base_module, connection_options, skip_tables)
      build_relationships!(database, relationships)
      database
    end

    # Creates ActiveRecord models from database tables
    # @param base_module [Module] The namespace for created models
    # @param connection_options [Hash] Database connection options
    # @param skip_tables [Array<String, Regexp>] Tables to exclude from model creation
    # @return [Database] The configured database instance
    def self.create_models!(base_module, connection_options, skip_tables)
      database = Database.new(base_module, connection_options)
      skip_tables.each do |table_name|
        table_name = Regexp.new("^#{table_name}") if table_name.include?('*')
        database.skip_table(table_name)
      end
      database.create_models!
      database
    end

    # Sets up relationships between created models
    # @param database [Database] The database instance containing the models
    # @param relationships [Hash] Custom foreign key relationships to add
    # @return [void]
    def self.build_relationships!(database, relationships)
      relations = Associations.new(database)
      relationships.each do |table_name, foreign_keys|
        foreign_keys.each do |foreign_key, relationship_name|
          relations.add_foreign_key(table_name, foreign_key, relationship_name)
        end
      end
      relations.build!
    end
  end
end
