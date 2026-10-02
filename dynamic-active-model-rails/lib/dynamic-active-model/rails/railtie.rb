# frozen_string_literal: true

module DynamicActiveModel
  module Rails
    # Hooks declared databases into Rails: eager loading, code reloading and
    # schema changes all rebuild models instead of leaving them stale.
    class Railtie < ::Rails::Railtie
      config.eager_load_namespaces << DynamicActiveModel::Rails

      # so config.active_support.deprecation (log, raise in tests, ...) applies
      initializer 'dynamic_active_model.deprecator' do |app|
        app.deprecators[:dynamic_active_model] = DynamicActiveModel.deprecator
      end

      initializer 'dynamic_active_model.schema_change_hook' do
        ActiveSupport.on_load(:active_record) { DynamicActiveModel::Rails::SchemaChangeHook.install }
      end

      initializer 'dynamic_active_model.reloader' do |app|
        app.reloader.before_class_unload { DynamicActiveModel::Rails.reset! }
        # a migration rewrites db/schema.rb (or structure.sql); reload so models rebuild
        app.config.watchable_dirs[app.root.join('db').to_s] = %i[rb sql]
      end
    end
  end
end
