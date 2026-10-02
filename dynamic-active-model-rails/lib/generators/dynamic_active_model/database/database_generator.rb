# frozen_string_literal: true

require 'rails/generators'
require_relative '../database_arguments'

module DynamicActiveModel
  module Generators
    # rails g dynamic_active_model:database NAME [--connection=NAME]
    class DatabaseGenerator < ::Rails::Generators::Base
      include DatabaseArguments

      desc 'Declares another database in config/initializers/dynamic_active_model.rb ' \
           '(e.g. cars => CarsDB in app/models/cars_db/).'

      argument :name, type: :string, banner: 'NAME'

      def check_initializer
        return if File.exist?(File.join(destination_root, INITIALIZER))

        raise Thor::Error, "#{INITIALIZER} not found; run rails g dynamic_active_model:install first"
      end

      def check_not_declared
        raise Thor::Error, "#{definition.module_name} is already declared" if declared?
      end

      def add_database
        inject_into_file INITIALIZER, "  #{add_database_line}\n", before: /^end\b/
      end

      def create_models_folder
        create_extensions_folder
      end

      def check_connection
        warn_about_missing_connection
      end

      private

      # @return [Boolean] Whether the app already declares this namespace
      def declared?
        DynamicActiveModel::Rails.configuration.definitions.any? { |db| db.module_name == definition.module_name }
      end
    end
  end
end
