# frozen_string_literal: true

# DynamicActiveModel module for create ActiveRecord models
module DynamicActiveModel
  autoload :Database, 'dynamic-active-model/database'
  autoload :Factory, 'dynamic-active-model/factory'
  autoload :ForeignKey, 'dynamic-active-model/foreign_key'
  autoload :Relations, 'dynamic-active-model/relations'
end
