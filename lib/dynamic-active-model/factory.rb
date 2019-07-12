# frozen_string_literal: true

module DynamicActiveModel
  class Factory
    def initialize(base_module, connection_options, base_class_name=nil)
      @base_module = base_module
      @connection_options = connection_options
      @base_class_name = base_class_name || :AbstractBase
    end

    def create(table_name, class_name=nil)
      class_name ||= generate_class_name(table_name)
      kls = Class.new(base_class) do
        self.table_name = table_name
      end
      @base_module.const_set(class_name, kls)
      @base_module.const_get(class_name)
    end

    def base_class
      @base_class ||=
        begin
          require 'active_record'

          kls = Class.new(ActiveRecord::Base) do
            self.abstract_class = true
          end
          @base_module.const_set(:AbstractBase, kls)

          kls = @base_module.const_get(@base_class_name)
          kls.establish_connection @connection_options
          kls
        end
    end

    def generate_class_name(table_name)
      table_name.classify
    end
  end
end
