# frozen_string_literal: true

module DynamicActiveModel
  module Rails
    # Resets every database's models after migrations run or a schema is loaded,
    # so models referenced later in the same process see the new schema. Covers
    # db:migrate, db:rollback, db:prepare, db:schema:load and maintain_test_schema!.
    module SchemaChangeHook
      # Prepended to ActiveRecord::Migrator
      module Migrator
        def migrate
          super
        ensure
          DynamicActiveModel::Rails.reset!
        end

        def run
          super
        ensure
          DynamicActiveModel::Rails.reset!
        end
      end

      # Prepended to ActiveRecord::Tasks::DatabaseTasks' singleton class
      module DatabaseTasks
        def load_schema(...)
          super
        ensure
          DynamicActiveModel::Rails.reset!
        end
      end

      # @return [void]
      def self.install
        ActiveRecord::Migrator.prepend(Migrator)
        ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(DatabaseTasks)
      end
    end
  end
end
