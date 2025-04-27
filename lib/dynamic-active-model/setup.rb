# frozen_string_literal: true
require 'inheritance-helper'

module DynamicActiveModel
  # DynamicActiveModel::Explorer creates models and relationships
  module Setup
    def self.included(base)
      base.extend InheritanceHelper::Methods
      base.extend ClassMethods
    end

    module ClassMethods
      def database
        nil
      end

      def connection_options
      end

      def connection_options=(options)
        redefine_class_method(:connection_options, options)
      end

      def set_connection_options(options)
        redefine_class_method(:connection_options, options)
      end

      def skip_tables
        []
      end

      def skip_tables=(tables)
        redefine_class_method(:skip_tables, tables)
      end

      def set_skip_tables(tables)
        redefine_class_method(:skip_tables, tables)
      end

      def skip_table(table)
        append_value_to_class_method(:skip_tables, table)
      end

      def relationships
        {}
      end

      def relationships=(all_relationships)
        redefine_class_method(:relationships, all_relationships)
      end

      def set_relationships(all_relationships)
        redefine_class_method(:relationships, all_relationships)
      end

      def foreign_key(table_name, foreign_key, relationship_name)
        current_relationships = relationships
        current_relationships[table_name] ||= {}
        current_relationships[table_name][foreign_key] = relationship_name
        redefine_class_method(:relationships, current_relationships)
      end

      def extensions_path
        nil
      end

      def extensions_path=(path)
        redefine_class_method(:extensions_path, path)
      end

      def set_extensions_path(path)
        redefine_class_method(:extensions_path, path)
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
