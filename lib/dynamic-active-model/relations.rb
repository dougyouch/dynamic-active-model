# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::Relations iterates over the models of a
  #  database and adds has_many and belongs_to based on foreign keys
  class Relations
    attr_reader :database

    def initialize(database)
      @database = database
      @foreign_keys = database.models.inject({}) do |memo, model|
        memo[model.table_name] = ForeignKey.new(model)
        memo
      end
    end

    def add_foreign_key(table_name, foreign_key)
      @foreign_keys[table_name].add(foreign_key)
    end

    # iterates over the models and adds relationships
    def build!
      foreign_key_to_models = {}
      @foreign_keys.each do |_, foreign_key|
        foreign_key.keys.each do |key|
          foreign_key_to_models[key] ||= []
          foreign_key_to_models[key] << foreign_key.model
        end
      end

      @database.models.each do |model|
        model.column_names.each do |column_name|
          next unless foreign_key_to_models[column_name]
          foreign_key_to_models[column_name].each do |foreign_model|
            next if foreign_model == model
            model.belongs_to(
              foreign_model.table_name.singularize.to_sym,
              class_name: foreign_model.name,
              foreign_key: column_name,
              primary_key: foreign_model.primary_key
            )
            foreign_model.has_many(
              model.table_name.pluralize.to_sym,
              class_name: model.name,
              foreign_key: column_name,
              primary_key: model.primary_key
            )
          end
        end
      end
    end
  end
end
