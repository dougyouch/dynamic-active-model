# frozen_string_literal: true

# DynamicActiveModel module for create ActiveRecord models
module DynamicActiveModel
  autoload :Database, 'dynamic-active-model/database'
  autoload :Explorer, 'dynamic-active-model/explorer'
  autoload :Factory, 'dynamic-active-model/factory'
  autoload :ForeignKey, 'dynamic-active-model/foreign_key'
  autoload :Associations, 'dynamic-active-model/associations'
  autoload :TemplateClassFile, 'dynamic-active-model/template_class_file'
end
