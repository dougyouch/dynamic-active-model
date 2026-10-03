# frozen_string_literal: true

module DynamicActiveModel
  # Adds has_many :through associations across join models. A join model is a
  # table with a primary key and a unique index on exactly two columns, each a
  # belongs_to to a different model; other columns (timestamps, audit columns,
  # extra data) don't matter. For user_roles with a unique (user_id, role_id):
  #
  #   User has_many :roles, through: :user_roles, source: :role
  #   Role has_many :users, through: :user_roles, source: :user
  #
  # A name already taken on the model (association, method or column) is skipped.
  # Tables without a primary key are has_and_belongs_to_many join tables instead.
  class HasManyThrough
    # @param models [Array<Class>] Models with their belongs_to/has_many already built
    # @param table_indexes [Hash] Indexes by table name (see Associations#table_indexes)
    def initialize(models, table_indexes)
      @models = models
      @table_indexes = table_indexes
    end

    # @return [void]
    def build!
      @models.each { |model| add_through_associations(model) }
    end

    private

    # @param join_model [Class]
    def add_through_associations(join_model)
      pair = join_belongs_to(join_model)
      return unless pair

      first, second = pair
      add_through(join_model, first, second)
      add_through(join_model, second, first)
    end

    # @param model [Class]
    # @return [Array<ActiveRecord::Reflection::BelongsToReflection>, nil] The two
    #   belongs_to a unique two-column index covers, if the model is a join model
    def join_belongs_to(model)
      return unless model.primary_key.is_a?(String)

      @table_indexes.fetch(model.table_name, []).each do |index|
        next unless index.unique && index.columns.is_a?(Array) && index.columns.size == 2

        reflections = index.columns.map { |column| belongs_to_for(model, column) }
        return reflections if reflections.all? && reflections.map(&:klass).uniq.size == 2
      end
      nil
    end

    # @return [ActiveRecord::Reflection::BelongsToReflection, nil]
    def belongs_to_for(model, column)
      model.reflect_on_all_associations(:belongs_to).find { |reflection| reflection.foreign_key.to_s == column }
    end

    # Gives the owner side of the join a has_many :through to the target side
    # @param join_model [Class]
    # @param owner [ActiveRecord::Reflection::BelongsToReflection] e.g. user_roles.user
    # @param target [ActiveRecord::Reflection::BelongsToReflection] e.g. user_roles.role
    def add_through(join_model, owner, target)
      through = join_association(owner.klass, join_model, owner.foreign_key.to_s)
      name = target.name.to_s.pluralize.to_sym
      return if through.nil? || taken?(owner.klass, name)

      owner.klass.has_many(name, through: through.name, source: target.name)
    end

    # @return [ActiveRecord::Reflection::HasManyReflection, nil] The owner's has_many
    #   to the join model over that foreign key, e.g. User has_many :user_roles
    def join_association(owner_model, join_model, foreign_key)
      owner_model.reflect_on_all_associations(:has_many).find do |reflection|
        reflection.options[:class_name] == join_model.name && reflection.options[:foreign_key].to_s == foreign_key
      end
    end

    # @return [Boolean] Whether the name is already an association, method or column
    def taken?(model, name)
      !model.reflect_on_association(name).nil? || model.method_defined?(name) ||
        model.column_names.include?(name.to_s)
    end
  end
end
