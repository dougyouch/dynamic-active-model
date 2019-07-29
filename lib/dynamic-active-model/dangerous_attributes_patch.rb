# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::DangerousAttributesPatch is used to remove dangerous attribute names
  # from attribute_names method in ActiveRecord
  module DangerousAttributesPatch
    def self.included(base)
      base.singleton_class.alias_method :original_attribute_names, :attribute_names
      base.extend ClassMethods
    end

    # no-doc
    module ClassMethods
      def attribute_names
        names = original_attribute_names
        names.reject! { |name| dangerous_attribute_method?(name) }
        names
      end
    end
  end
end
