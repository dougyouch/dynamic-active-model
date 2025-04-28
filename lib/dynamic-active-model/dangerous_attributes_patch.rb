# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::DangerousAttributesPatch is used to remove dangerous attribute names
  # from attribute_names method in ActiveRecord
  module DangerousAttributesPatch
    def self.included(base)
      return unless base.attribute_names

      columns_to_ignore = base.columns.select do |column|
        if column.type == :boolean
          base.dangerous_attribute_method?(column.name) ||
            base.dangerous_attribute_method?(column.name + '?')
        else
          base.dangerous_attribute_method?(column.name)
        end
      end
      base.ignored_columns = columns_to_ignore.map(&:name)
    end
  end
end
