# frozen_string_literal: true

module DynamicActiveModel
  module Generators
    # Shared --connection option and helpers for generators that declare a database
    module DatabaseArguments
      INITIALIZER = 'config/initializers/dynamic_active_model.rb'

      def self.included(base)
        base.class_option :connection,
                          type: :string,
                          desc: "database.yml entry to connect to (default: share ApplicationRecord's connection)"
      end

      private

      # @return [DynamicActiveModel::Rails::DatabaseDefinition] Naming for the NAME argument
      def definition
        @definition ||= DynamicActiveModel::Rails::DatabaseDefinition.new(name)
      end

      # @return [String] e.g. "config.add_database :cars, :cars"
      def add_database_line
        args = [name.underscore.to_sym.inspect]
        args << options[:connection].to_sym.inspect if options[:connection]
        "config.add_database #{args.join(', ')}"
      end

      # Creates the database's models folder for its extension files
      # @return [void]
      def create_extensions_folder
        create_file File.join(definition.extensions_path(destination_root), '.keep')
      end

      # Warns when --connection names a database.yml entry the current environment lacks
      # @return [void]
      def warn_about_missing_connection
        return unless options[:connection]
        return if ActiveRecord::Base.configurations.configs_for(env_name: ::Rails.env, name: options[:connection])

        say_status :warning, "config/database.yml has no #{options[:connection]} entry for #{::Rails.env}", :yellow
      end
    end
  end
end
