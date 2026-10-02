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
  # @example With Foreign Key Constraints
  #   DynamicActiveModel::Explorer.explore(DB, database_config, foreign_key_constraints: true)
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
    # @param table_class_names [Hash] Custom class names by table name
    # @param parent_class [Class, nil] Optional superclass for the base class (see Factory)
    # @param foreign_key_constraints [Boolean] Also relate columns through the database's
    #   foreign key constraints (see ForeignKeyConstraints)
    # @return [Database] The configured database instance
    # @raise [ClassNameConflict] If two tables map to the same class name
    def self.explore(base_module, connection_options, skip_tables = [], relationships = {}, table_class_names = {},
                     parent_class: nil, foreign_key_constraints: false)
      database = create_models!(base_module, connection_options, skip_tables, table_class_names,
                                parent_class: parent_class)
      build_relationships!(database, relationships, foreign_key_constraints: foreign_key_constraints)
      database
    end

    # Creates ActiveRecord models from database tables
    # @param base_module [Module] The namespace for created models
    # @param connection_options [Hash] Database connection options
    # @param skip_tables [Array<String, Regexp>] Tables to exclude from model creation
    # @param table_class_names [Hash] Custom class names by table name
    # @param parent_class [Class, nil] Optional superclass for the base class (see Factory)
    # @return [Database] The configured database instance
    def self.create_models!(base_module, connection_options, skip_tables, table_class_names = {}, parent_class: nil)
      database = Database.new(base_module, connection_options, parent_class: parent_class)
      skip_tables.each { |table| database.skip_table(skip_table_matcher(table)) }
      table_class_names.each { |table_name, class_name| database.table_class_name(table_name, class_name) }
      database.create_models!
      database
    end

    # Converts a table name containing * wildcards into an anchored Regexp
    # @param table [String, Regexp] Table name, wildcard pattern, or Regexp
    # @return [String, Regexp] The table name or matching Regexp
    def self.skip_table_matcher(table)
      return table unless table.is_a?(String) && table.include?('*')

      Regexp.new("\\A#{Regexp.escape(table).gsub('\\*', '.*')}\\z")
    end

    # Sets up relationships between created models
    # @param database [Database] The database instance containing the models
    # @param relationships [Hash] Custom foreign key relationships to add
    # @param foreign_key_constraints [Boolean] Also relate columns through foreign key constraints
    # @return [void]
    def self.build_relationships!(database, relationships, foreign_key_constraints: false)
      relations = Associations.new(database)
      relations.use_foreign_key_constraints! if foreign_key_constraints
      relationships.each do |table_name, foreign_keys|
        foreign_keys.each do |foreign_key, relationship_name|
          relations.add_foreign_key(table_name, foreign_key, relationship_name)
        end
      end
      relations.build!
    end
  end
end
