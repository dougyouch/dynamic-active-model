# frozen_string_literal: true

RSpec.describe DynamicActiveModel::Rails::ModelReport do
  subject(:report) { described_class.new(loaders).to_s }

  let(:loaders) { DynamicActiveModel::Rails.loaders }

  it "lists a database sharing ApplicationRecord's connection with its models and associations" do
    expect(report).to include("AppDB (shares ApplicationRecord's connection), 2 models\n")
    expect(report).to include("  AppDB::Post (posts)\n    belongs_to :user -> AppDB::User\n")
    expect(report).to include("  AppDB::User (users)\n    has_many :posts -> AppDB::Post\n")
  end

  it 'names a database.yml connection' do
    expect(report).to include("CarsDB (connection: :cars), 2 models\n")
  end

  it 'shows connects_to roles' do
    connects_to = DynamicActiveModel::Rails.configuration.definitions.last.connects_to
    expect(report).to include("FleetDB (connects_to: #{connects_to.inspect}), 2 models\n")
  end

  context 'with a custom connection, a join model and a single model' do
    let(:definition) do
      config = { adapter: 'sqlite3', database: DummySchema.path(:primary), password: 'secret' }
      DynamicActiveModel::Rails::DatabaseDefinition.new(:plain, config, has_many_through: true)
                                                   .tap { |db| db.include_tables 'users', 'posts', 'post_editors' }
    end
    let(:single) do
      DynamicActiveModel::Rails::DatabaseDefinition.new(:single).tap { |db| db.include_tables 'users' }
    end
    let(:loaders) do
      [definition, single].map do |db|
        DynamicActiveModel::Rails::DatabaseLoader.new(db, Dir.tmpdir).tap do |loader|
          DynamicActiveModel::Rails::LazyNamespace.define(stub_const(db.module_name, Module.new).name, loader)
        end
      end
    end

    before do
      DummySchema.execute(:primary, <<~SQL)
        CREATE TABLE post_editors (id INTEGER PRIMARY KEY, post_id INTEGER, user_id INTEGER);
        CREATE UNIQUE INDEX index_post_editors_on_post_id_and_user_id ON post_editors (post_id, user_id);
      SQL
    end

    after do
      loaders.each(&:reset!)
      DummySchema.execute(:primary, 'DROP TABLE IF EXISTS post_editors')
    end

    it 'describes the connection without printing it' do
      expect(report).to include('PlainDB (custom connection), 3 models')
      expect(report).not_to include('secret')
    end

    it 'shows through associations' do
      expect(report).to include('    has_many :users -> PlainDB::User, through: :post_editors')
    end

    it 'uses the singular for one model' do
      expect(report).to include("SingleDB (shares ApplicationRecord's connection), 1 model\n")
    end
  end
end
