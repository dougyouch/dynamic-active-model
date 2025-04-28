# frozen_string_literal: true

require 'inheritance-helper'

module DynamicActiveModel
  # DynamicActiveModel::Explorer creates models and relationships
  module Setup
    def self.included(base)
      base.extend InheritanceHelper::Methods
      base.extend ClassMethods
    end

    # ClassMethods various class methods for configuring a module
    module ClassMethods
      def database
        nil
      end

      def dynamic_active_model_config
        {
          connection_options: nil,
          skip_tables: [],
          relationships: {},
          extensions_path: nil
        }
      end

      def connection_options(options = nil)
        if options
          config = dynamic_active_model_config
          config[:connection_options] = options
          redefine_class_method(:dynamic_active_model_config, config)
        end
        dynamic_active_model_config[:connection_options]
      end

      def skip_tables(tables = nil)
        if tables
          config = dynamic_active_model_config
          config[:skip_tables] = tables
          redefine_class_method(:dynamic_active_model_config, config)
        end
        dynamic_active_model_config[:skip_tables]
      end

      def skip_table(table)
        config = dynamic_active_model_config
        config[:skip_tables] << table
        redefine_class_method(:dynamic_active_model_config, config)
      end

      def relationships(all_relationships = nil)
        if all_relationships
          config = dynamic_active_model_config
          config[:relationships] = all_relationships
          redefine_class_method(:dynamic_active_model_config, config)
        end
        dynamic_active_model_config[:relationships]
      end

      def foreign_key(table_name, foreign_key, relationship_name)
        config = dynamic_active_model_config
        current_relationships = config[:relationships]
        current_relationships[table_name] ||= {}
        current_relationships[table_name][foreign_key] = relationship_name
        redefine_class_method(:dynamic_active_model_config, config)
      end

      def extensions_path(path = nil)
        if path
          config = dynamic_active_model_config
          config[:extensions_path] = path
          redefine_class_method(:dynamic_active_model_config, config)
        end
        dynamic_active_model_config[:extensions_path]
      end

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
        database.update_all_models(extensions_path) if extensions_path
        database
      end
    end
  end
end
