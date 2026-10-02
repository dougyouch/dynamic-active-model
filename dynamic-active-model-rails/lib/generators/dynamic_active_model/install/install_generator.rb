# frozen_string_literal: true

require 'rails/generators'
require_relative '../database_arguments'

module DynamicActiveModel
  module Generators
    # rails g dynamic_active_model:install [NAME] [--connection=NAME]
    class InstallGenerator < ::Rails::Generators::Base
      include DatabaseArguments

      source_root File.expand_path('templates', __dir__)
      desc 'Creates config/initializers/dynamic_active_model.rb declaring a first database ' \
           '(default: db, i.e. DB in app/models/db/).'

      argument :name, type: :string, default: 'db', banner: 'NAME'

      def create_initializer
        template 'dynamic_active_model.rb.tt', INITIALIZER
      end

      def create_models_folder
        create_extensions_folder
      end

      def check_connection
        warn_about_missing_connection
      end
    end
  end
end
