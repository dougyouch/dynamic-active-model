# frozen_string_literal: true

require 'monitor'

module DynamicActiveModel
  module Rails
    # Builds one declared database's models on demand and tears them down again.
    # Loading is synchronized so concurrent first references build only once.
    # After every build it runs the database's ActiveSupport load hook, so
    # ActiveSupport.on_load(:cars_db) { ... } reapplies after reloads and migrations.
    class DatabaseLoader
      # @return [DatabaseDefinition]
      attr_reader :definition

      # @param definition [DatabaseDefinition]
      # @param root [Pathname, String] Application root, for the extensions folder
      def initialize(definition, root)
        @definition = definition
        @root = root
        @monitor = Monitor.new
      end

      # Builds the models unless already built
      # @return [DynamicActiveModel::Database]
      def load!
        @monitor.synchronize { build unless @database }
        @database
      end

      # The class that owns the database's connection, for role and shard switching:
      # the generated base class, or the parent class when sharing its connection
      # @return [Class]
      def connection_class
        base_class = load!.factory.base_class
        definition.own_connection? ? base_class : base_class.superclass
      end

      # @return [Boolean] Whether models are built (or being built)
      def loaded?
        !@database.nil?
      end

      # Removes the built models, and the schema cache their columns and indexes
      # came from, so the next #load! rebuilds them against the current schema
      # @return [void]
      def reset!
        @monitor.synchronize do
          if @database
            clear_schema_cache
            @database.reset!
          end
          @database = nil
        end
      end

      private

      # Creates models, relationships and extensions, then runs load hooks;
      # undoes a partial build on error
      # @return [void]
      def build
        @database = new_database
        @database.create_models!
        Explorer.build_relationships!(@database, definition.relationships,
                                      foreign_key_constraints: definition.foreign_key_constraints,
                                      has_many_through: definition.has_many_through)
        load_extensions
        ActiveSupport.run_load_hooks(definition.load_hook, @database)
      rescue StandardError
        reset!
        raise
      end

      # Clears the schema cache of the pool the models use. Rails clears only the
      # primary pool on code reload, and nothing on schema changes outside migrations.
      # @return [void]
      def clear_schema_cache
        # schema_reflection rather than schema_cache: ConnectionPool#schema_cache is 7.2+
        @database.models.map(&:connection_pool).uniq.each { |pool| pool.schema_reflection.clear! }
      end

      # @return [DynamicActiveModel::Database] A database configured from the definition
      def new_database
        Database.new(namespace, definition.connection, parent_class: parent_class).tap do |database|
          database.factory.base_class.connects_to(**definition.connects_to) if definition.connects_to
          definition.skipped_tables.each { |table| database.skip_table(Explorer.skip_table_matcher(table)) }
          definition.included_tables.each { |table| database.include_table(Explorer.skip_table_matcher(table)) }
          definition.table_class_names.each { |table, class_name| database.table_class_name(table, class_name) }
        end
      end

      # Applies the database's extension files. The default folder is optional;
      # a configured extensions_path must exist.
      # @return [void]
      # @raise [DynamicActiveModel::Error] If a configured extensions_path is missing
      def load_extensions
        path = definition.extensions_path(@root)
        if File.directory?(path)
          @database.update_all_models(path, definition.extensions_suffix)
        elsif definition.custom_extensions_path?
          raise DynamicActiveModel::Error, "extensions_path #{path} for #{definition.module_name} does not exist"
        end
      end

      # @return [Module] The namespace models are defined in
      def namespace
        Object.const_get(definition.module_name)
      end

      # @return [Class] The base class's superclass, resolved now so it can be reloaded
      def parent_class
        Object.const_get(definition.parent_class_name)
      end
    end
  end
end
