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

      # @return [Array<String, Regexp>] Tables (or patterns) to model; empty means all
      attr_reader :included_tables

      # @return [String] File suffix of extension files
      attr_reader :extensions_suffix

      # @return [Hash, nil] Keyword arguments for the base class's connects_to
      attr_reader :connects_to

      # @return [Hash] Custom relationship names by table and foreign key
      attr_reader :relationships

      # @return [Hash] Custom class names by table name
      attr_reader :table_class_names

      # @param name [Symbol, String] Database name
      # @param connection [Symbol, String, Hash, nil] See Configuration#add_database
      # @param module_name [String, nil] Namespace override, e.g. "Inventory"
      # @param parent_class [String] Superclass for the generated base class
      # @param extensions_path [String, nil] Extensions directory, absolute or relative to
      #   the app root; defaults to app/models/<folder>, which may be absent
      # @param extensions_suffix [String] File suffix of extension files
      # @param connects_to [Hash, nil] Roles ({ writing: :cars, reading: :cars_replica }) or
      #   connects_to's own arguments ({ database: ..., shards: ... })
      # @raise [ArgumentError] If both a connection and connects_to are given
      def initialize(name, connection = nil, module_name: nil, parent_class: 'ApplicationRecord',
                     extensions_path: nil, extensions_suffix: '.ext.rb', connects_to: nil)
        raise ArgumentError, 'pass either a connection or connects_to:, not both' if connection && connects_to

        @connection = connection
        @connects_to = connects_to && normalize_connects_to(connects_to)
        @module_name = module_name || default_module_name(name)
        @parent_class_name = parent_class.to_s
        @extensions_path = extensions_path&.to_s
        @extensions_suffix = extensions_suffix
        @skipped_tables = []
        @included_tables = []
        @relationships = {}
        @table_class_names = {}
      end

      # @return [String] Folder under app/models for extensions, e.g. "cars_db"
      def folder
        module_name.underscore
      end

      # @return [Symbol] ActiveSupport load hook run after each build, e.g. :cars_db
      def load_hook
        folder.to_sym
      end

      # @param root [Pathname, String] Application root
      # @return [String] Absolute directory holding this database's extension files
      def extensions_path(root)
        File.expand_path(@extensions_path || File.join('app', 'models', folder), root.to_s)
      end

      # @return [Boolean] Whether the generated base class owns its connection, rather
      #   than sharing the parent class's
      def own_connection?
        !(connection.nil? && connects_to.nil?)
      end

      # @return [Boolean] Whether extensions_path was configured, so it must exist
      def custom_extensions_path?
        !@extensions_path.nil?
      end

      # Skips tables; strings may use * wildcards
      # @param tables [Array<String, Regexp>]
      # @return [void]
      def skip_tables(*tables)
        @skipped_tables.concat(tables.flatten)
      end

      # Models only these tables; strings may use * wildcards. ActiveRecord's
      # internal tables still need their exact name.
      # @param tables [Array<String, Regexp>]
      # @return [void]
      def include_tables(*tables)
        @included_tables.concat(tables.flatten)
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

      # Treats a hash of roles as connects_to's database: argument
      # @param options [Hash]
      # @return [Hash]
      def normalize_connects_to(options)
        options.key?(:database) || options.key?(:shards) ? options : { database: options }
      end

      # :cars => "CarsDB", :grant_db => "GrantDB", :db => "DB"
      # @param name [Symbol, String]
      # @return [String]
      def default_module_name(name)
        "#{name.to_s.underscore.sub(/(?:\A|_)db\z/, '').camelize}DB"
      end
    end
  end
end
