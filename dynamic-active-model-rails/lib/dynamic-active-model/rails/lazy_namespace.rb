# frozen_string_literal: true

module DynamicActiveModel
  module Rails
    # Extended into a database's namespace module (e.g. CarsDB). The first
    # reference to a missing constant builds the database's models.
    module LazyNamespace
      # @return [DatabaseLoader]
      attr_accessor :dynamic_active_model_loader

      # Defines (or reuses) a top-level namespace module and makes it lazy
      # @param module_name [String]
      # @param loader [DatabaseLoader]
      # @return [Module]
      def self.define(module_name, loader)
        namespace =
          if Object.const_defined?(module_name, false)
            Object.const_get(module_name, false)
          else
            Object.const_set(module_name, Module.new)
          end
        namespace.extend(self)
        namespace.dynamic_active_model_loader = loader
        namespace
      end

      # @return [DynamicActiveModel::Database] The built database
      def database
        dynamic_active_model_loader.load!
      end

      # @return [Array<Class>] Every model in the namespace
      def models
        database.models
      end

      # Switches role or shard for this database's models, like ActiveRecord's
      # connected_to, e.g. CarsDB.connected_to(role: :reading) { CarsDB::Car.count }
      # @return [Object] The block's result
      def connected_to(**, &)
        dynamic_active_model_loader.connection_class.connected_to(**, &)
      end

      # Builds the models on first reference, then retries the lookup
      # @param name [Symbol]
      # @return [Object]
      def const_missing(name)
        return super if dynamic_active_model_loader.loaded?

        dynamic_active_model_loader.load!
        const_defined?(name, false) ? const_get(name, false) : super
      end
    end
  end
end
