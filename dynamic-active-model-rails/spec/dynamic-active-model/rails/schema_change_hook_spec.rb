# frozen_string_literal: true

require 'tmpdir'

RSpec.describe DynamicActiveModel::Rails::SchemaChangeHook do
  let(:dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(dir) }

  describe 'migrations' do
    let(:version) { 20_260_101_000_000 }
    let(:context) { ActiveRecord::MigrationContext.new(dir) }

    before do
      File.write(File.join(dir, "#{version}_create_widgets.rb"), <<~RUBY)
        class CreateWidgets < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]
          def change
            create_table :widgets
          end
        end
      RUBY
    end

    it 'rebuilds models after migrating up and down' do
      AppDB.database
      context.migrate
      expect(AppDB::Widget.table_name).to eq('widgets')

      context.run(:down, version)
      expect { AppDB::Widget }.to raise_error(NameError)
    end
  end

  describe 'schema loads' do
    let(:schema_file) { File.join(dir, 'schema.rb') }
    let(:db_config) { ActiveRecord::Base.configurations.configs_for(env_name: 'test', name: 'primary') }

    before do
      File.write(schema_file, <<~RUBY)
        ActiveRecord::Schema[#{ActiveRecord::Migration.current_version}].define do
          create_table :trucks, force: true
        end
      RUBY
    end

    after { DummySchema.execute(:primary, 'DROP TABLE IF EXISTS trucks') }

    it 'rebuilds models after loading a schema' do
      AppDB.database
      ActiveRecord::Tasks::DatabaseTasks.load_schema(db_config, :ruby, schema_file)
      expect(AppDB::Truck.table_name).to eq('trucks')
    end
  end
end
