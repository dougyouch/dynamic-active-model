# frozen_string_literal: true

module DynamicActiveModel
  module Rails
    # Writes a class file per model (TemplateClassFile) for every declared
    # database, for bin/rails dynamic_active_model:export. Useful to read what
    # the gem generates, or as a starting point for a hand-written model.
    class ModelExport
      # @param loaders [Array<DatabaseLoader>]
      def initialize(loaders)
        @loaders = loaders
      end

      # @param dir [String] Output directory; files land in dir/<namespace>/<model>.rb
      # @return [Array<String>] Paths written
      def export!(dir)
        @loaders.flat_map { |loader| loader.load!.models }.map do |model|
          DynamicActiveModel::TemplateClassFile.new(model).create_template!(dir)
          File.join(dir, "#{model.name.underscore}.rb")
        end
      end
    end
  end
end
