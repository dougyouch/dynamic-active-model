# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::ForeignKey tracks foreign keys related to the model
  class ForeignKey
    attr_reader :model,
                :keys

    DEFAULT_ID_SUFFIX = '_id'

    def self.id_suffix
      @id_suffix || DEFAULT_ID_SUFFIX
    end

    # rubocop:disable Style/TrivialAccessors
    def self.id_suffix=(val)
      @id_suffix = val
    end
    # rubocop:enable Style/TrivialAccessors

    def initialize(model)
      @model = model
      @keys = {}
      add(generate_foreign_key(model.table_name), model.table_name.underscore)
    end

    def add(key, relationship_name)
      @keys[key] = relationship_name
    end

    def generate_foreign_key(table_name)
      table_name.singularize + self.class.id_suffix
    end
  end
end
