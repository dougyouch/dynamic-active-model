# frozen_string_literal: true

require 'inheritance-helper'

module DynamicActiveModel
  # The Setup module provides configuration and initialization methods for
  # DynamicActiveModel. It allows you to:
  # - Configure database connections
  # - Specify tables to skip
  # - Define custom relationships
  # - Set up model extensions
  #
  # @example Basic Usage
  #   module DB
  #     include DynamicActiveModel::Setup
  #     connection_options database_config
  #     skip_tables ['temporary_data']
  #     create_models!
  #   end
  #
  # @example Sharing ApplicationRecord's Connection
  #   module DB
  #     include DynamicActiveModel::Setup
  #     parent_class ApplicationRecord
  #     create_models!
  #   end
  #
  # @example With Custom Relationships
  #   module DB
  #     include DynamicActiveModel::Setup
  #     foreign_key 'users', 'manager_id', 'manager'
  #     create_models!
  #   end
  module Setup
    # Extends the including module with configuration methods
    # @param base [Module] The module including this module
    def self.included(base)
      base.extend InheritanceHelper::Methods
      base.extend ClassMethods
    end

    # ClassMethods provides various class methods for configuring a module
    module ClassMethods
      # Gets the database instance
      # @return [Database, nil] The configured database instance
      def database
        nil
      end

      # Gets the current configuration
      # @return [Hash] The configuration hash with default values
      def dynamic_active_model_config
        {
          connection_options: nil,
          parent_class: nil,
          foreign_key_constraints: false,
          skip_tables: [],
          relationships: {},
          table_class_names: {},
          extensions_path: nil,
          extensions_suffix: '.ext.rb'
        }
      end

      # Sets or gets the database connection options
      # @param options [Hash, Symbol, String, nil] Anything establish_connection accepts:
      #   a config hash, a URL, or a Symbol naming a database.yml entry for the
      #   current environment
      # @return [Hash, Symbol, String] The current connection options
      # @raise [ArgumentError] For a database.yml name given as a String
      def connection_options(options = nil)
        reject_database_yml_name!(options) if options.is_a?(String)

        update_config(:connection_options, options) if options

        dynamic_active_model_config[:connection_options]
      end

      # Sets or gets the superclass for the generated base class. Without connection
      # options, models inherit the parent class's connection.
      # @param klass [Class, nil] Superclass, e.g. ApplicationRecord
      # @return [Class, nil] The current parent class
      def parent_class(klass = nil)
        update_config(:parent_class, klass) if klass
        dynamic_active_model_config[:parent_class]
      end

      # Sets or gets whether columns are also related through the database's foreign
      # key constraints (see ForeignKeyConstraints)
      # @param enabled [Boolean, nil]
      # @return [Boolean] The current setting
      def foreign_key_constraints(enabled = nil)
        update_config(:foreign_key_constraints, enabled) unless enabled.nil?
        dynamic_active_model_config[:foreign_key_constraints]
      end

      # Sets or gets the list of tables to skip
      # @param tables [Array<String>, nil] Tables to skip
      # @return [Array<String>] The current list of skipped tables
      def skip_tables(tables = nil)
        update_config(:skip_tables, tables) if tables
        dynamic_active_model_config[:skip_tables]
      end

      # Adds a single table to the skip list
      # @param table [String] Table to skip
      def skip_table(table)
        config = dynamic_active_model_config
        config[:skip_tables] << table
        redefine_class_method(:dynamic_active_model_config, config)
      end

      # Sets or gets the custom relationships
      # @param all_relationships [Hash, nil] All custom relationships
      # @return [Hash] The current relationships
      def relationships(all_relationships = nil)
        update_config(:relationships, all_relationships) if all_relationships
        dynamic_active_model_config[:relationships]
      end

      # Adds a custom foreign key relationship
      # @param table_name [String] Name of the table
      # @param foreign_key [String] Name of the foreign key column
      # @param relationship_name [String] Name for the relationship
      def foreign_key(table_name, foreign_key, relationship_name)
        config = dynamic_active_model_config
        current_relationships = config[:relationships]
        current_relationships[table_name] ||= {}
        current_relationships[table_name][foreign_key] = relationship_name
        redefine_class_method(:dynamic_active_model_config, config)
      end

      # Sets a custom class name for a table
      # @param table_name [String] Name of the table
      # @param class_name [String] Class name to use for the table's model
      def table_class_name(table_name, class_name)
        config = dynamic_active_model_config
        config[:table_class_names][table_name.to_s] = class_name
        redefine_class_method(:dynamic_active_model_config, config)
      end

      # Gets the custom class names by table name
      # @return [Hash] The current table class names
      def table_class_names
        dynamic_active_model_config[:table_class_names]
      end

      # Sets or gets the path for model extensions
      # @param path [String, nil] Path to extension files
      # @return [String, nil] The current extensions path
      def extensions_path(path = nil)
        update_config(:extensions_path, path) if path
        dynamic_active_model_config[:extensions_path]
      end

      # Sets or gets the suffix for extension files
      # @param suffix [String, nil] File extension suffix
      # @return [String] The current extensions suffix
      def extensions_suffix(suffix = nil)
        update_config(:extensions_suffix, suffix) if suffix
        dynamic_active_model_config[:extensions_suffix]
      end

      # Creates all models and applies extensions
      # This method:
      # 1. Creates models using Explorer
      # 2. Applies any model extensions if configured
      # @return [Database] The configured database instance
      def create_models!
        redefine_class_method(
          :database,
          DynamicActiveModel::Explorer.explore(
            self,
            connection_options,
            skip_tables,
            relationships,
            table_class_names,
            parent_class: parent_class,
            foreign_key_constraints: foreign_key_constraints
          )
        )
        database.update_all_models(extensions_path, extensions_suffix) if extensions_path
        database
      end

      private

      # A String database.yml name was deprecated in 0.16 and removed in 1.0. Without
      # this check it would reach establish_connection as a URL and fail confusingly.
      # @param options [String]
      # @raise [ArgumentError] Unless the String is a URL
      def reject_database_yml_name!(options)
        return if options.include?('://')

        raise ArgumentError,
              "connection_options no longer accepts a database.yml name as a String (#{options.inspect}); " \
              "pass a Symbol instead (connection_options #{options.to_sym.inspect})"
      end

      # Stores a single configuration value
      # @param key [Symbol] Configuration key
      # @param value [Object] Configuration value
      def update_config(key, value)
        config = dynamic_active_model_config
        config[key] = value
        redefine_class_method(:dynamic_active_model_config, config)
      end
    end
  end
end
