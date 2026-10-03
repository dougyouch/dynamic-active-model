# frozen_string_literal: true

module DynamicActiveModel
  # Rails integration for DynamicActiveModel. Declare each database once in an
  # initializer; its models are built lazily on first reference, rebuilt after
  # migrations, and reloaded with the rest of the app in development.
  #
  # @example config/initializers/dynamic_active_model.rb
  #   DynamicActiveModel::Rails.configure do |config|
  #     config.add_database :grant_db                # ApplicationRecord's connection
  #     config.add_database :cars, :cars do |db|     # "cars" entry in database.yml
  #       db.skip_tables 'legacy_*'
  #     end
  #   end
  #
  #   GrantDB::User.first
  #   CarsDB::Car.where(make: 'Honda')
  module Rails
    autoload :AutoloaderSetup, 'dynamic-active-model/rails/autoloader_setup'
    autoload :Configuration, 'dynamic-active-model/rails/configuration'
    autoload :DatabaseDefinition, 'dynamic-active-model/rails/database_definition'
    autoload :DatabaseLoader, 'dynamic-active-model/rails/database_loader'
    autoload :LazyNamespace, 'dynamic-active-model/rails/lazy_namespace'
    autoload :ModelExport, 'dynamic-active-model/rails/model_export'
    autoload :ModelReport, 'dynamic-active-model/rails/model_report'
    autoload :SchemaChangeHook, 'dynamic-active-model/rails/schema_change_hook'

    class << self
      # Declares databases. Each new database gets its namespace module and
      # autoloader settings immediately, so call this from an initializer.
      # @yieldparam config [Configuration]
      # @return [Configuration]
      def configure
        yield configuration
        configuration.definitions.each { |definition| register(definition) }
        configuration
      end

      # @return [Configuration] The process-wide configuration
      def configuration
        @configuration ||= Configuration.new
      end

      # @return [Array<DatabaseLoader>] A loader per declared database
      def loaders
        @loaders ||= []
      end

      # Builds every database's models. Rails calls this when eager loading.
      # @return [void]
      def eager_load!
        loaders.each(&:load!)
      end

      # Forgets every database's models so they rebuild on next reference
      # @return [void]
      def reset!
        loaders.each(&:reset!)
      end

      private

      # Sets up the namespace and autoloader for a definition not seen before
      # @param definition [DatabaseDefinition]
      # @return [void]
      def register(definition)
        return if loaders.any? { |loader| loader.definition.equal?(definition) }

        loader = DatabaseLoader.new(definition, ::Rails.root)
        LazyNamespace.define(definition.module_name, loader)
        AutoloaderSetup.new(::Rails.autoloaders, definition, ::Rails.root).apply
        loaders << loader
      end
    end
  end
end
