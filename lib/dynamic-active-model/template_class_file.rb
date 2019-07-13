# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::TemplateClassFile creates ActiveRecord file for model
  class TemplateClassFile
    def initialize(model)
      @model = model
    end

    def create_template!(dir)
      file = dir + '/' + @model.name.underscore + '.rb'
      File.open(file, 'wb') { |f| f.write(to_s) }
    end

    def to_s
      str = "class #{@model.name} < ActiveRecord::Base\n".dup
      str << "  self.table_name = #{@model.table_name.to_sym.inspect}\n" unless @model.name.underscore.pluralize == @model.table_name
      all_has_many_relationships.each do |assoc|
        append_association!(str, assoc)
      end
      all_belongs_to_relationships.each do |assoc|
        append_association!(str, assoc)
      end
      str << "end\n"
      str
    end

    private

    def all_has_many_relationships
      @model.reflect_on_all_associations.select do |assoc|
        assoc.is_a?(ActiveRecord::Reflection::HasManyReflection)
      end
    end

    def all_belongs_to_relationships
      @model.reflect_on_all_associations.select do |assoc|
        assoc.is_a?(ActiveRecord::Reflection::BelongsToReflection)
      end
    end

    def append_association!(str, assoc)
      assoc_type = assoc.is_a?(ActiveRecord::Reflection::HasManyReflection) ? 'has_many' : 'belongs_to'
      association_options = assoc_type == 'has_many' ? has_many_association_options(assoc) : belongs_to_association_options(assoc)
      str << "  #{assoc_type} #{assoc.name.inspect}"
      unless association_options.empty?
        association_options.each do |name, value|
          str << ", #{name}: '#{value}'"
        end
      end
      str << "\n"
    end

    def has_many_association_options(assoc)
      options = {}
      options[:class_name] = assoc.options[:class_name] unless assoc.options[:class_name].underscore.pluralize == assoc.name.to_s
      options[:foreign_key] = assoc.options[:foreign_key] unless assoc.options[:foreign_key] == default_foreign_key_name
      options[:primary_key] = assoc.options[:primary_key] unless assoc.options[:primary_key] == 'id'
      options
    end

    def belongs_to_association_options(assoc)
      options = {}
      options[:class_name] = assoc.options[:class_name] unless assoc.options[:class_name] == assoc.name.to_s.classify
      options[:foreign_key] = assoc.options[:foreign_key] unless assoc.options[:foreign_key] == (assoc.options[:class_name].underscore + '_id')
      options[:primary_key] = assoc.options[:primary_key] unless assoc.options[:primary_key] == 'id'
      options
    end

    def default_foreign_key_name
      @model.table_name.underscore.singularize + '_id'
    end

    def const_get(class_name)
      class_name.split('::').inject(Object) { |mod, name| mod.const_get(name) }
    end
  end
end
