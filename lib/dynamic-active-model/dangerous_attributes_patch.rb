# frozen_string_literal: true

module DynamicActiveModel
  # The DangerousAttributesPatch module is a safety feature that prevents conflicts
  # between database column names and Ruby reserved words or ActiveRecord methods.
  # It automatically detects and ignores columns that could cause conflicts,
  # particularly focusing on boolean columns that might conflict with Ruby's
  # question mark methods.
  #
  # @example Basic Usage
  #   class User < ActiveRecord::Base
  #     include DynamicActiveModel::DangerousAttributesPatch
  #   end
  #
  # @example With Boolean Column
  #   # If a table has a boolean column named 'class',
  #   # it will be automatically ignored to prevent conflicts
  #   # with Ruby's Object#class method
  module DangerousAttributesPatch
    # Extends the including class with dangerous attribute protection
    # This method:
    # 1. Checks if the class has any attributes
    # 2. Identifies columns that could cause conflicts
    # 3. Adds those columns to the ignored_columns list
    #
    # @param base [Class] The ActiveRecord model class
    def self.included(base)
      return unless base.attribute_names

      columns_to_ignore = base.columns.select do |column|
        if column.type == :boolean
          base.dangerous_attribute_method?(column.name) ||
            base.dangerous_attribute_method?("#{column.name}?")
        else
          base.dangerous_attribute_method?(column.name)
        end
      end
      base.ignored_columns = columns_to_ignore.map(&:name)
    end
  end
end
