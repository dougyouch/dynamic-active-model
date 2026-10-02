# frozen_string_literal: true

module DynamicActiveModel
  module Rails
    # Collects the databases declared in DynamicActiveModel::Rails.configure
    class Configuration
      # @return [Array<DatabaseDefinition>] Declared databases, in order
      attr_reader :definitions

      def initialize
        @definitions = []
      end

      # Declares a database whose tables become models in a <Name>DB namespace
      # @param name [Symbol, String] Database name, e.g. :cars => CarsDB, app/models/cars_db/
      # @param connection [Symbol, String, Hash, nil] database.yml entry name, URL or
      #   config hash; nil shares the parent class's connection
      # @param ** [Hash] DatabaseDefinition options (module_name:, parent_class:)
      # @yieldparam definition [DatabaseDefinition] For table-level settings
      # @return [DatabaseDefinition]
      # @raise [ArgumentError] If the namespace is already declared
      def add_database(name, connection = nil, **)
        definition = DatabaseDefinition.new(name, connection, **)
        raise ArgumentError, "#{definition.module_name} is already declared" if declared?(definition.module_name)

        yield definition if block_given?
        @definitions << definition
        definition
      end

      private

      # @param module_name [String]
      # @return [Boolean] Whether a database already uses the namespace
      def declared?(module_name)
        @definitions.any? { |definition| definition.module_name == module_name }
      end
    end
  end
end
