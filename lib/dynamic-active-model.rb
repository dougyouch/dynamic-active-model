# frozen_string_literal: true

# DynamicActiveModel is a Ruby gem that provides automatic database discovery,
# model creation, and relationship mapping for Rails applications.
#
# It allows developers to dynamically create ActiveRecord models from existing
# database schemas without manually writing model classes. The gem automatically
# detects and sets up relationships including has_many, belongs_to, has_one,
# and has_and_belongs_to_many based on database constraints.
#
# @example Basic Usage
#   module DB; end
#   DynamicActiveModel::Explorer.explore(DB, database_config)
#
# @example Model Extension
#   db = DynamicActiveModel::Database.new(DB, database_config)
#   db.update_model(:users) do
#     def full_name
#       "#{first_name} #{last_name}"
#     end
#   end
module DynamicActiveModel
  # Database class handles database connection and model creation
  autoload :Database, 'dynamic-active-model/database'

  # Safety feature that prevents conflicts with Ruby reserved words
  autoload :DangerousAttributesPatch, 'dynamic-active-model/dangerous_attributes_patch'

  # High-level interface for model discovery and relationship mapping
  autoload :Explorer, 'dynamic-active-model/explorer'

  # Manages the creation of model classes
  autoload :Factory, 'dynamic-active-model/factory'

  # Handles foreign key relationships and constraints
  autoload :ForeignKey, 'dynamic-active-model/foreign_key'

  # Manages automatic discovery and setup of model relationships
  autoload :Associations, 'dynamic-active-model/associations'

  # Handles generation of model class files
  autoload :TemplateClassFile, 'dynamic-active-model/template_class_file'

  # Manages the setup process and configuration
  autoload :Setup, 'dynamic-active-model/setup'

  # Raised when a requested model cannot be found
  class ModelNotFound < StandardError; end
end
