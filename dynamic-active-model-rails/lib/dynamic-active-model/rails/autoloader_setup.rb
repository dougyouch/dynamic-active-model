# frozen_string_literal: true

module DynamicActiveModel
  module Rails
    # Teaches the Rails autoloader about a database's folder: cars_db/ maps to
    # CarsDB (only in Zeitwerk, not the global inflector), and extension files
    # (*.ext.rb by default) are left to DynamicActiveModel instead of being autoloaded.
    class AutoloaderSetup
      # @param autoloaders [Rails::Autoloaders]
      # @param definition [DatabaseDefinition]
      # @param root [Pathname, String] Application root
      def initialize(autoloaders, definition, root)
        @autoloaders = autoloaders
        @definition = definition
        @root = root
      end

      # Must run before the main autoloader is set up, i.e. from an initializer
      # @return [void]
      def apply
        @autoloaders.main.inflector.inflect(@definition.folder => @definition.module_name)
        @autoloaders.main.ignore(extension_glob)
      end

      private

      # @return [String] Glob matching the database's extension files
      def extension_glob
        File.join(@definition.extensions_path(@root), "*#{@definition.extensions_suffix}")
      end
    end
  end
end
