# frozen_string_literal: true

require 'monitor'

module DynamicActiveModel
  module Rails
    # Builds one declared database's models on demand and tears them down again.
    # Loading is synchronized so concurrent first references build only once.
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

      # @return [Boolean] Whether models are built (or being built)
      def loaded?
        !@database.nil?
      end

      # Removes the built models so the next #load! rebuilds them
      # @return [void]
      def reset!
        @monitor.synchronize do
          @database&.reset!
          @database = nil
        end
      end

      private

      # Creates models, relationships and extensions; undoes a partial build on error
      # @return [void]
      def build
        @database = new_database
        @database.create_models!
        Explorer.build_relationships!(@database, definition.relationships)
        load_extensions
      rescue StandardError
        reset!
        raise
      end

      # @return [DynamicActiveModel::Database] A database configured from the definition
      def new_database
        Database.new(namespace, definition.connection, parent_class: parent_class).tap do |database|
          definition.skipped_tables.each { |table| database.skip_table(Explorer.skip_table_matcher(table)) }
          definition.table_class_names.each { |table, class_name| database.table_class_name(table, class_name) }
        end
      end

      # Applies the .ext.rb files in the database's models folder
      # @return [void]
      def load_extensions
        path = definition.extensions_path(@root)
        @database.update_all_models(path) if File.directory?(path)
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
