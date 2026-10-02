# frozen_string_literal: true

require 'rails/generators'

module DynamicActiveModel
  module Generators
    # rails g dynamic_active_model:extension DATABASE TABLE
    class ExtensionGenerator < ::Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      desc 'Creates an extension file for a table of a declared database ' \
           '(e.g. grant_db users => app/models/grant_db/users.ext.rb).'

      argument :database, type: :string, banner: 'DATABASE'
      argument :table, type: :string, banner: 'TABLE'

      def create_extension
        template 'extension.rb.tt', File.join(definition.extensions_path(destination_root), file_name)
      end

      private

      # The declared database named by DATABASE, as a name (grant_db) or namespace (GrantDB)
      # @return [DynamicActiveModel::Rails::DatabaseDefinition]
      # @raise [Thor::Error] If no such database is declared
      def definition
        @definition ||= declared.find { |db| [database, default_module_name].include?(db.module_name) } ||
                        raise(Thor::Error, "no database #{database} is declared " \
                                           "(declared: #{declared.map(&:module_name).join(', ')})")
      end

      # @return [Array<DynamicActiveModel::Rails::DatabaseDefinition>]
      def declared
        DynamicActiveModel::Rails.configuration.definitions
      end

      # @return [String] Namespace DATABASE maps to by default, e.g. "GrantDB"
      def default_module_name
        DynamicActiveModel::Rails::DatabaseDefinition.new(database).module_name
      end

      # @return [String] e.g. "users.ext.rb"
      def file_name
        "#{table}#{definition.extensions_suffix}"
      end

      # @return [String] e.g. "GrantDB::User"
      def model_name
        "#{definition.module_name}::#{definition.table_class_names[table] || table.classify}"
      end
    end
  end
end
