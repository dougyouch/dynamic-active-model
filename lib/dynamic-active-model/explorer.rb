# frozen_string_literal: true

module DynamicActiveModel
  # DynamicActiveModel::EWplorer creates models and relationships
  module Explorer
    def self.explore(base_module, connection_options, skip_tables = [], relationships = {})
      database = create_models!(base_module, connection_options, skip_tables)
      build_relationships!(database, relationships)
    end

    def self.create_models!(base_module, connection_options, skip_tables)
      database = Database.new(base_module, connection_options)
      skip_tables.each do |table_name|
        table_name = Regexp.new("^#{table_name}") if table_name.include?('*')
        database.skip_table(table_name)
      end
      database.create_models!
      database
    end

    def self.build_relationships!(database, relationships)
      relations = Relations.new(database)
      relationships.each do |table_name, foreign_keys|
        foreign_keys.each do |foreign_key, relationship_name|
          relations.add_foreign_key(table_name, foreign_key, relationship_name)
        end
      end
      relations.build!
    end
  end
end
