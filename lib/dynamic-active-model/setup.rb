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
          skip_tables: [],
          relationships: {},
          extensions_path: nil,
          extensions_suffix: '.ext.rb'
        }
      end

      # Sets or gets the database connection options
      # @param options [Hash, String, nil] Database configuration or named configuration
      # @return [Hash] The current connection options
      def connection_options(options = nil)
        if options.is_a?(String)
          name = options
          options = ActiveRecord::Base
                    .configurations
                    .configs_for(
                      env_name: Rails.env,
                      name: name
                    )
                    .configuration_hash
        end

        if options
          config = dynamic_active_model_config
          config[:connection_options] = options
          redefine_class_method(:dynamic_active_model_config, config)
        end

        dynamic_active_model_config[:connection_options]
      end

      # Sets or gets the list of tables to skip
      # @param tables [Array<String>, nil] Tables to skip
      # @return [Array<String>] The current list of skipped tables
      def skip_tables(tables = nil)
        if tables
          config = dynamic_active_model_config
          config[:skip_tables] = tables
          redefine_class_method(:dynamic_active_model_config, config)
        end
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
        if all_relationships
          config = dynamic_active_model_config
          config[:relationships] = all_relationships
          redefine_class_method(:dynamic_active_model_config, config)
        end
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

      # Sets or gets the path for model extensions
      # @param path [String, nil] Path to extension files
      # @return [String, nil] The current extensions path
      def extensions_path(path = nil)
        if path
          config = dynamic_active_model_config
          config[:extensions_path] = path
          redefine_class_method(:dynamic_active_model_config, config)
        end
        dynamic_active_model_config[:extensions_path]
      end

      # Sets or gets the suffix for extension files
      # @param suffix [String, nil] File extension suffix
      # @return [String] The current extensions suffix
      def extensions_suffix(suffix = nil)
        if suffix
          config = dynamic_active_model_config
          config[:extensions_suffix] = suffix
          redefine_class_method(:dynamic_active_model_config, config)
        end
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
            relationships
          )
        )
        database.update_all_models(extensions_path, extensions_suffix) if extensions_path
        database
      end
    end
  end
end
