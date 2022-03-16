# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::DangerousAttributesPatch is used to remove dangerous attribute names
  # from attribute_names method in ActiveRecord
  module DangerousAttributesPatch
    def self.included(base)
      if base.attribute_names
        columns_to_ignore = base.attribute_names.select { |name| base.dangerous_attribute_method?(name) }
        base.ignored_columns = columns_to_ignore
      end
    end
  end
end
