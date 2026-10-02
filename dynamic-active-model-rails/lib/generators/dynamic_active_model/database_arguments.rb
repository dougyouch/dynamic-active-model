# frozen_string_literal: true

module DynamicActiveModel
  module Generators
    # Shared --connection/--replica options and helpers for generators that declare a database
    module DatabaseArguments
      INITIALIZER = 'config/initializers/dynamic_active_model.rb'

      def self.included(base)
        base.class_option :connection,
                          type: :string,
                          desc: "database.yml entry to connect to (default: share ApplicationRecord's connection)"
        base.class_option :replica,
                          type: :string,
                          desc: 'database.yml entry for the reading role (requires --connection)'
      end

      private

      # @return [DynamicActiveModel::Rails::DatabaseDefinition] Naming for the NAME argument
      def definition
        @definition ||= DynamicActiveModel::Rails::DatabaseDefinition.new(name)
      end

      # @return [String] e.g. "config.add_database :cars, :cars"
      # @raise [Thor::Error] If --replica is given without --connection
      def add_database_line
        "config.add_database #{[name.underscore.to_sym.inspect, *connection_args].join(', ')}"
      end

      # @return [Array<String>] Connection arguments for add_database
      def connection_args
        return [] unless options[:connection]
        return [options[:connection].to_sym.inspect] unless options[:replica]

        roles = { writing: options[:connection], reading: options[:replica] }
        ["connects_to: { #{roles.map { |role, entry| "#{role}: #{entry.to_sym.inspect}" }.join(', ')} }"]
      end

      # Fails before anything is generated when --replica lacks --connection
      # @return [void]
      def check_replica_has_connection
        return unless options[:replica] && !options[:connection]

        raise Thor::Error, '--replica requires --connection (the writing database)'
      end

      # Creates the database's models folder for its extension files
      # @return [void]
      def create_extensions_folder
        create_file File.join(definition.extensions_path(destination_root), '.keep')
      end

      # Warns when --connection or --replica names a database.yml entry the current environment lacks
      # @return [void]
      def warn_about_missing_connection
        options.values_at(:connection, :replica).compact.each do |entry|
          next if configured?(entry)

          say_status :warning, "config/database.yml has no #{entry} entry for #{::Rails.env}", :yellow
        end
      end

      # @param entry [String] database.yml entry name
      # @return [Boolean] Whether the current environment has it; replica: true
      #   entries are hidden unless asked for
      def configured?(entry)
        !ActiveRecord::Base.configurations.configs_for(env_name: ::Rails.env, name: entry, include_hidden: true).nil?
      end
    end
  end
end
