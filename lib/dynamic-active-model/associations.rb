# frozen_string_literal: true

module DynamicActiveModel
  # The Associations class is responsible for automatically detecting and setting up
  # ActiveRecord relationships between models based on database schema analysis.
  # It supports the following relationship types:
  # - belongs_to
  # - has_many
  # - has_one (automatically detected from unique constraints)
  # - has_and_belongs_to_many (automatically detected from join tables)
  #
  # @example Basic Usage
  #   db = DynamicActiveModel::Database.new(DB, database_config)
  #   db.create_models!
  #   associations = DynamicActiveModel::Associations.new(db)
  #   associations.build!
  #
  # @example Custom Foreign Key
  #   associations.add_foreign_key('users', 'manager_id', 'manager')
  class Associations
    # @return [Database] The database instance containing the models
    attr_reader :database
    
    # @return [Hash] Mapping of table names to their indexes
    attr_reader :table_indexes
    
    # @return [Array] List of detected join tables
    attr_reader :join_tables

    # Initializes a new Associations instance
    # @param database [Database] The database instance containing the models
    def initialize(database)
      @database = database
      @table_indexes = {}
      @join_tables = []
      @foreign_keys = {}
      database.models.each do |model|
        @foreign_keys[model.table_name] = ForeignKey.new(model)
        @table_indexes[model.table_name] = model.connection.indexes(model.table_name)
        @join_tables << model if join_table?(model)
      end
    end

    # Adds a custom foreign key relationship
    # @param table_name [String] Name of the table with the foreign key
    # @param foreign_key [String] Name of the foreign key column
    # @param relationship_name [String, nil] Custom name for the relationship
    def add_foreign_key(table_name, foreign_key, relationship_name = nil)
      @foreign_keys[table_name].add(foreign_key, relationship_name)
    end

    # Builds all relationships between models based on foreign keys and constraints
    # This method:
    # 1. Maps foreign keys to their corresponding models
    # 2. Adds belongs_to relationships
    # 3. Adds has_many or has_one relationships based on unique constraints
    # 4. Sets up has_and_belongs_to_many relationships for join tables
    # @return [void]
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

      @join_tables.each do |join_table_model|
        models = join_table_model.column_names.map { |column_name| foreign_key_to_models[column_name.downcase]&.first&.first }.compact
        if models.size == 2
          add_has_and_belongs_to_many(join_table_model, models)
        end
      end
    end

    private

    # Adds has_and_belongs_to_many relationships between two models
    # @param join_table_model [Class] The join table model
    # @param models [Array<Class>] The two models to be related
    def add_has_and_belongs_to_many(join_table_model, models)
      model1, model2 = *models
      model1.has_and_belongs_to_many model2.table_name.pluralize.to_sym, join_table: join_table_model.table_name, class_name: model2.name
      model2.has_and_belongs_to_many model1.table_name.pluralize.to_sym, join_table: join_table_model.table_name, class_name: model1.name
    end

    # Adds appropriate relationships between two models
    # @param relationship_name [String] Name of the relationship
    # @param model [Class] The model with the foreign key
    # @param belongs_to_model [Class] The model being referenced
    # @param foreign_key [String] The foreign key column name
    def add_relationships(relationship_name, model, belongs_to_model, foreign_key)
      add_belongs_to(relationship_name, model, belongs_to_model, foreign_key)
      if unique_index?(model, foreign_key)
        add_has_one(relationship_name, belongs_to_model, model, foreign_key)
      else
        add_has_many(relationship_name, belongs_to_model, model, foreign_key)
      end
    end

    # Adds a belongs_to relationship to a model
    # @param relationship_name [String] Name of the relationship
    # @param model [Class] The model with the foreign key
    # @param belongs_to_model [Class] The model being referenced
    # @param foreign_key [String] The foreign key column name
    def add_belongs_to(relationship_name, model, belongs_to_model, foreign_key)
      model.belongs_to(
        relationship_name.singularize.to_sym,
        class_name: belongs_to_model.name,
        foreign_key: foreign_key,
        primary_key: belongs_to_model.primary_key
      )
    end

    # Adds a has_many relationship to a model
    # @param relationship_name [String] Name of the relationship
    # @param model [Class] The model with the foreign key
    # @param has_many_model [Class] The model being referenced
    # @param foreign_key [String] The foreign key column name
    def add_has_many(relationship_name, model, has_many_model, foreign_key)
      model.has_many(
        generate_has_many_association_name(relationship_name, model, has_many_model),
        class_name: has_many_model.name,
        foreign_key: foreign_key,
        primary_key: has_many_model.primary_key
      )
    end

    # Adds a has_one relationship to a model
    # @param relationship_name [String] Name of the relationship
    # @param model [Class] The model with the foreign key
    # @param has_one_model [Class] The model being referenced
    # @param foreign_key [String] The foreign key column name
    def add_has_one(relationship_name, model, has_one_model, foreign_key)
      model.has_one(
        generate_has_one_association_name(relationship_name, model, has_one_model),
        class_name: has_one_model.name,
        foreign_key: foreign_key,
        primary_key: has_one_model.primary_key
      )
    end

    # Creates a mapping of foreign key column names to their corresponding models
    # @return [Hash] Mapping of foreign key names to model and relationship name pairs
    def create_foreign_key_to_model_map
      @foreign_keys.values.each_with_object({}) do |foreign_key, hsh|
        foreign_key.keys.each do |key, relationship_name|
          hsh[key.downcase] ||= []
          hsh[key.downcase] << [foreign_key.model, relationship_name]
        end
      end
    end

    # Generates an appropriate name for a has_many association
    # @param relationship_name [String] Original relationship name
    # @param model [Class] The model with the foreign key
    # @param has_many_model [Class] The model being referenced
    # @return [Symbol] The generated association name
    def generate_has_many_association_name(relationship_name, model, has_many_model)
      name =
        if relationship_name == model.table_name.underscore
          has_many_model.table_name
        else
          relationship_name
        end
      name.underscore.pluralize.to_sym
    end

    # Generates an appropriate name for a has_one association
    # @param relationship_name [String] Original relationship name
    # @param model [Class] The model with the foreign key
    # @param has_one_model [Class] The model being referenced
    # @return [Symbol] The generated association name
    def generate_has_one_association_name(relationship_name, model, has_one_model)
      name =
        if relationship_name == model.table_name.underscore
          has_one_model.table_name
        else
          relationship_name
        end
      name.underscore.singularize.to_sym
    end

    # Checks if a foreign key column has a unique index
    # @param model [Class] The model to check
    # @param foreign_key [String] The foreign key column name
    # @return [Boolean] Whether the foreign key has a unique index
    def unique_index?(model, foreign_key)
      indexes = table_indexes[model.table_name]
      indexes.any? do |index|
        index.unique &&
          index.columns.size == 1 &&
          index.columns.first == foreign_key
      end
    end

    # Detects if a model represents a join table for has_and_belongs_to_many
    # @param model [Class] The model to check
    # @return [Boolean] Whether the model is a join table
    def join_table?(model)
      model.primary_key.nil? &&
        model.columns.size == 2 &&
        model.columns.all? { |column| column.name =~ /#{ForeignKey.id_suffix}$/ }
    end
  end
end
