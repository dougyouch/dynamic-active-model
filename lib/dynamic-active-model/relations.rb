# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::Relations iterates over the models of a
  #  database and adds has_many and belongs_to based on foreign keys
  class Relations
    attr_reader :database

    def initialize(database)
      @database = database
      @foreign_keys = database.models.each_with_object({}) do |model, hsh|
        hsh[model.table_name] = ForeignKey.new(model)
      end
    end

    def add_foreign_key(table_name, foreign_key, relationship_name)
      @foreign_keys[table_name].add(foreign_key, relationship_name)
    end

    # iterates over the models and adds relationships
    def build!
      foreign_key_to_models = create_foreign_key_to_model_map

      @database.models.each do |model|
        model.column_names.each do |column_name|
          next unless foreign_key_to_models[column_name]

          foreign_key_to_models[column_name].each do |foreign_model, relationship_name|
            next if foreign_model == model

            add_relationships(relationship_name, model, foreign_model, column_name)
          end
        end
      end
    end

    private

    def add_relationships(relationship_name, model, belongs_to_model, foreign_key)
      add_belongs_to(relationship_name, model, belongs_to_model, foreign_key)
      add_has_many(belongs_to_model, model, foreign_key)
    end

    def add_belongs_to(relationship_name, model, belongs_to_model, foreign_key)
      model.belongs_to(
        relationship_name.singularize.to_sym,
        class_name: belongs_to_model.name,
        foreign_key: foreign_key,
        primary_key: belongs_to_model.primary_key
      )
    end

    def add_has_many(model, has_many_model, foreign_key)
      model.has_many(
        has_many_model.table_name.pluralize.to_sym,
        class_name: has_many_model.name,
        foreign_key: foreign_key,
        primary_key: has_many_model.primary_key
      )
    end

    def create_foreign_key_to_model_map
      @foreign_keys.values.each_with_object({}) do |foreign_key, hsh|
        foreign_key.keys.each do |key, relationship_name|
          hsh[key] ||= []
          hsh[key] << [foreign_key.model, relationship_name]
        end
      end
    end
  end
end
