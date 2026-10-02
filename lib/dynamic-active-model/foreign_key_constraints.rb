# frozen_string_literal: true

module DynamicActiveModel
  # Reads the database's foreign key constraints and resolves them to models, so
  # Associations can relate columns that don't follow the <table>_id naming
  # convention (posts.author_id => users) and self-references (employees.manager_id).
  #
  # Skipped: composite constraints, columns without the id suffix (a belongs_to
  # named after the column itself would hide it), and constraints whose table or
  # referenced table has no model.
  #
  # @example
  #   constraints = DynamicActiveModel::ForeignKeyConstraints.new(database)
  #   constraints.find(DB::Post, 'author_id') # => #<struct referenced_model=DB::User, ...>
  class ForeignKeyConstraints
    # A constraint resolved to models
    Constraint = Struct.new(:model, :column, :referenced_model, :primary_key, :relationship_name)

    # @param database [Database] The database whose models' constraints to read
    def initialize(database)
      @database = database
      @constraints = database.models.flat_map { |model| constraints_for(model) }
                             .to_h { |constraint| [[constraint.model, constraint.column], constraint] }
    end

    # @param model [Class] The model with the column
    # @param column [String] The column name
    # @return [Constraint, nil] The column's constraint, if it has one
    def find(model, column)
      @constraints[[model, column]]
    end

    # @return [Integer] Number of usable constraints
    def size
      @constraints.size
    end

    private

    # @param model [Class]
    # @return [Array<Constraint>] The model's usable constraints
    def constraints_for(model)
      model.connection.foreign_keys(model.table_name).filter_map do |foreign_key|
        column = foreign_key.column
        next unless column.is_a?(String) && column.end_with?(ForeignKey.id_suffix)

        referenced_model = @database.get_model(foreign_key.to_table)
        next unless referenced_model

        Constraint.new(model, column, referenced_model, foreign_key.primary_key,
                       relationship_name(column, referenced_model))
      end
    end

    # Names the relationship like the naming convention does: author_id => "author",
    # but user_id referencing users => "users", so its has_many stays :posts
    # @param column [String]
    # @param referenced_model [Class]
    # @return [String]
    def relationship_name(column, referenced_model)
      name = column.delete_suffix(ForeignKey.id_suffix)
      table_name = referenced_model.table_name.underscore
      name == table_name.singularize ? table_name : name
    end
  end
end
