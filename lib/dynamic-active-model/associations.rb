# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::Associations iterates over the models of a
  #  database and adds has_many and belongs_to based on foreign keys
  class Associations
    attr_reader :database,
                :table_indexes

    def initialize(database)
      @database = database
      @table_indexes = {}
      @foreign_keys = database.models.each_with_object({}) do |model, hsh|
        hsh[model.table_name] = ForeignKey.new(model)
        @table_indexes[model.table_name] = model.connection.indexes(model.table_name)
      end
    end

    def add_foreign_key(table_name, foreign_key, relationship_name = nil)
      @foreign_keys[table_name].add(foreign_key, relationship_name)
    end

    # iterates over the models and adds relationships
    def build!
      foreign_key_to_models = create_foreign_key_to_model_map

      @database.models.each do |model|
        model.column_names.each do |column_name|
          next unless foreign_key_to_models[column_name.downcase]

          foreign_key_to_models[column_name.downcase].each do |foreign_model, relationship_name|
            next if foreign_model == model

            add_relationships(relationship_name, model, foreign_model, column_name)
          end
        end
      end
    end

    private

    def add_relationships(relationship_name, model, belongs_to_model, foreign_key)
      add_belongs_to(relationship_name, model, belongs_to_model, foreign_key)
      if unique_index?(model, foreign_key)
        add_has_one(relationship_name, belongs_to_model, model, foreign_key)
      else
        add_has_many(relationship_name, belongs_to_model, model, foreign_key)
      end
    end

    def add_belongs_to(relationship_name, model, belongs_to_model, foreign_key)
      model.belongs_to(
        relationship_name.singularize.to_sym,
        class_name: belongs_to_model.name,
        foreign_key: foreign_key,
        primary_key: belongs_to_model.primary_key
      )
    end

    def add_has_many(relationship_name, model, has_many_model, foreign_key)
      model.has_many(
        generate_has_many_association_name(relationship_name, model, has_many_model),
        class_name: has_many_model.name,
        foreign_key: foreign_key,
        primary_key: has_many_model.primary_key
      )
    end

    def add_has_one(relationship_name, model, has_one_model, foreign_key)
      model.has_one(
        generate_has_one_association_name(relationship_name, model, has_one_model),
        class_name: has_one_model.name,
        foreign_key: foreign_key,
        primary_key: has_one_model.primary_key
      )
    end

    def create_foreign_key_to_model_map
      @foreign_keys.values.each_with_object({}) do |foreign_key, hsh|
        foreign_key.keys.each do |key, relationship_name|
          hsh[key.downcase] ||= []
          hsh[key.downcase] << [foreign_key.model, relationship_name]
        end
      end
    end

    def generate_has_many_association_name(relationship_name, model, has_many_model)
      name =
        if relationship_name == model.table_name.underscore
          has_many_model.table_name
        else
          relationship_name
        end
      name.underscore.pluralize.to_sym
    end

    def generate_has_one_association_name(relationship_name, model, has_one_model)
      name =
        if relationship_name == model.table_name.underscore
          has_one_model.table_name
        else
          relationship_name
        end
      name.underscore.singularize.to_sym
    end

    def unique_index?(model, foreign_key)
      indexes = table_indexes[model.table_name]
      indexes.any? do |index|
        index.unique &&
          index.columns.size == 1 &&
          index.columns.first == foreign_key
      end
    end
  end
end
