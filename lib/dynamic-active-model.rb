# frozen_string_literal: true

# DynamicActiveModel module for create ActiveRecord models
module DynamicActiveModel
  autoload :Database, 'dynamic-active-model/database'
  autoload :DangerousAttributesPatch, 'dynamic-active-model/dangerous_attributes_patch'
  autoload :Explorer, 'dynamic-active-model/explorer'
  autoload :Factory, 'dynamic-active-model/factory'
  autoload :ForeignKey, 'dynamic-active-model/foreign_key'
  autoload :Associations, 'dynamic-active-model/associations'
  autoload :TemplateClassFile, 'dynamic-active-model/template_class_file'

  def self.base_models_path
    @base_models_path || 'app/models'
  end

  def self.base_models_path=(path)
    @base_models_path = path
  end
end
