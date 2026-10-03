# frozen_string_literal: true

module DynamicActiveModel
  module Rails
    # A plain-text listing of each declared database's models and associations,
    # for bin/rails dynamic_active_model:models. Builds the databases it lists.
    #
    # @example
    #   GrantDB (shares ApplicationRecord's connection), 2 models
    #     GrantDB::Role (roles)
    #       has_many :users -> GrantDB::User, through: :user_roles
    class ModelReport
      # @param loaders [Array<DatabaseLoader>]
      def initialize(loaders)
        @loaders = loaders
      end

      # @return [String]
      def to_s
        @loaders.map { |loader| database_section(loader) }.join("\n")
      end

      private

      # @param loader [DatabaseLoader]
      # @return [String]
      def database_section(loader)
        models = loader.load!.models.sort_by(&:name)
        lines = ["#{loader.definition.module_name} (#{connection_description(loader.definition)}), " \
                 "#{models.size} #{models.size == 1 ? 'model' : 'models'}"]
        models.each { |model| lines.concat(model_lines(model)) }
        "#{lines.join("\n")}\n"
      end

      # Describes the connection without printing URLs or config hashes, which
      # can hold passwords
      # @param definition [DatabaseDefinition]
      # @return [String]
      def connection_description(definition)
        return "connects_to: #{definition.connects_to.inspect}" if definition.connects_to
        return "connection: #{definition.connection.inspect}" if definition.connection.is_a?(Symbol)
        return 'custom connection' if definition.connection

        "shares #{definition.parent_class_name}'s connection"
      end

      # @param model [Class]
      # @return [Array<String>]
      def model_lines(model)
        ["  #{model.name} (#{model.table_name})"] +
          model.reflect_on_all_associations.sort_by { |reflection| reflection.name.to_s }.map do |reflection|
            "    #{association_line(reflection)}"
          end
      end

      # @param reflection [ActiveRecord::Reflection::AssociationReflection]
      # @return [String] e.g. "has_many :users -> GrantDB::User, through: :user_roles"
      def association_line(reflection)
        line = "#{reflection.macro} #{reflection.name.inspect} -> #{reflection.klass.name}"
        reflection.options[:through] ? "#{line}, through: #{reflection.options[:through].inspect}" : line
      end
    end
  end
end
