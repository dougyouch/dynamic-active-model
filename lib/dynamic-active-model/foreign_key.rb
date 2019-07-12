# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::ForeignKey tracks foreign keys related to the model
  class ForeignKey
    attr_reader :model,
                :keys

    def initialize(model)
      @model = model
      @keys = []
      add(generate_foreign_key(model.table_name))
    end

    def add(key)
      @keys << key
    end

    def generate_foreign_key(table_name)
      table_name.singularize + '_id'
    end
  end
end
