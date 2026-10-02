# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'

module DynamicActiveModel
  module Rails
    # Settings for one declared database: its connection, namespace, folder and
    # table-level options. Names always end in DB so a namespace never collides
    # with an application class: :cars => CarsDB in app/models/cars_db/.
    class DatabaseDefinition
      # @return [Symbol, String, Hash, nil] Connection passed to establish_connection
      attr_reader :connection

      # @return [String] Name of the namespace module, e.g. "CarsDB"
      attr_reader :module_name

      # @return [String] Name of the base class's superclass, constantized at load time
      attr_reader :parent_class_name

      # @return [Array<String, Regexp>] Tables (or patterns) to skip
      attr_reader :skipped_tables

      # @return [Hash] Custom relationship names by table and foreign key
      attr_reader :relationships

      # @return [Hash] Custom class names by table name
      attr_reader :table_class_names

      # @param name [Symbol, String] Database name
      # @param connection [Symbol, String, Hash, nil] See Configuration#add_database
      # @param module_name [String, nil] Namespace override, e.g. "Inventory"
      # @param parent_class [String] Superclass for the generated base class
      def initialize(name, connection = nil, module_name: nil, parent_class: 'ApplicationRecord')
        @connection = connection
        @module_name = module_name || default_module_name(name)
        @parent_class_name = parent_class.to_s
        @skipped_tables = []
        @relationships = {}
        @table_class_names = {}
      end

      # @return [String] Folder under app/models for extensions, e.g. "cars_db"
      def folder
        module_name.underscore
      end

      # @param root [Pathname, String] Application root
      # @return [String] Directory holding this database's .ext.rb files
      def extensions_path(root)
        File.join(root.to_s, 'app', 'models', folder)
      end

      # Skips tables; strings may use * wildcards
      # @param tables [Array<String, Regexp>]
      # @return [void]
      def skip_tables(*tables)
        @skipped_tables.concat(tables.flatten)
      end

      # Names the relationship for a foreign key column
      # @param table_name [String, Symbol]
      # @param foreign_key [String, Symbol] Column name
      # @param relationship_name [String, Symbol]
      # @return [void]
      def foreign_key(table_name, foreign_key, relationship_name)
        (@relationships[table_name.to_s] ||= {})[foreign_key.to_s] = relationship_name.to_s
      end

      # Overrides the model class name for a table
      # @param table_name [String, Symbol]
      # @param class_name [String]
      # @return [void]
      def table_class_name(table_name, class_name)
        @table_class_names[table_name.to_s] = class_name.to_s
      end

      private

      # :cars => "CarsDB", :grant_db => "GrantDB"
      # @param name [Symbol, String]
      # @return [String]
      def default_module_name(name)
        "#{name.to_s.underscore.delete_suffix('_db').camelize}DB"
      end
    end
  end
end
