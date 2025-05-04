# frozen_string_literal: true

module DynamicActiveModel
  # The TemplateClassFile class generates Ruby source files for ActiveRecord models.
  # It creates properly formatted class definitions that include:
  # - Table name configuration
  # - Has many relationships
  # - Belongs to relationships
  # - Custom association options
  #
  # @example Basic Usage
  #   model = DB::User
  #   template = DynamicActiveModel::TemplateClassFile.new(model)
  #   template.create_template!('app/models')
  #
  # @example Generate Source String
  #   model = DB::User
  #   template = DynamicActiveModel::TemplateClassFile.new(model)
  #   source = template.to_s
  class TemplateClassFile
    # Initializes a new TemplateClassFile instance
    # @param model [Class] The ActiveRecord model to generate a template for
    def initialize(model)
      @model = model
    end

    # Creates a Ruby source file for the model
    # @param dir [String] Directory to create the file in
    # @return [void]
    def create_template!(dir)
      file = dir + '/' + @model.name.underscore + '.rb'
      File.open(file, 'wb') { |f| f.write(to_s) }
    end

    # Generates the Ruby source code for the model
    # @return [String] The complete model class definition
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

    # Gets all has_many relationships for the model
    # @return [Array<ActiveRecord::Reflection::HasManyReflection>]
    def all_has_many_relationships
      @model.reflect_on_all_associations.select do |assoc|
        assoc.is_a?(ActiveRecord::Reflection::HasManyReflection)
      end
    end

    # Gets all belongs_to relationships for the model
    # @return [Array<ActiveRecord::Reflection::BelongsToReflection>]
    def all_belongs_to_relationships
      @model.reflect_on_all_associations.select do |assoc|
        assoc.is_a?(ActiveRecord::Reflection::BelongsToReflection)
      end
    end

    # Appends an association definition to the source string
    # @param str [String] The source string being built
    # @param assoc [ActiveRecord::Reflection::AssociationReflection] The association to add
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

    # Gets the options for a has_many association
    # @param assoc [ActiveRecord::Reflection::HasManyReflection] The association
    # @return [Hash] The association options
    def has_many_association_options(assoc)
      options = {}
      options[:class_name] = assoc.options[:class_name] unless assoc.options[:class_name].underscore.pluralize == assoc.name.to_s
      options[:foreign_key] = assoc.options[:foreign_key] unless assoc.options[:foreign_key] == default_foreign_key_name
      options[:primary_key] = assoc.options[:primary_key] unless assoc.options[:primary_key] == 'id'
      options
    end

    # Gets the options for a belongs_to association
    # @param assoc [ActiveRecord::Reflection::BelongsToReflection] The association
    # @return [Hash] The association options
    def belongs_to_association_options(assoc)
      options = {}
      options[:class_name] = assoc.options[:class_name] unless assoc.options[:class_name] == assoc.name.to_s.classify
      options[:foreign_key] = assoc.options[:foreign_key] unless assoc.options[:foreign_key] == (assoc.options[:class_name].underscore + '_id')
      options[:primary_key] = assoc.options[:primary_key] unless assoc.options[:primary_key] == 'id'
      options
    end

    # Gets the default foreign key name for the model
    # @return [String] The default foreign key name
    def default_foreign_key_name
      @model.table_name.underscore.singularize + '_id'
    end

    # Gets a constant by its fully qualified name
    # @param class_name [String] The fully qualified class name
    # @return [Class] The resolved class
    def const_get(class_name)
      class_name.split('::').inject(Object) { |mod, name| mod.const_get(name) }
    end
  end
end
