# frozen_string_literal: true

require 'tmpdir'

RSpec.describe DynamicActiveModel::Rails::DatabaseLoader do
  describe 'a build that fails part way' do
    let(:root) { Dir.mktmpdir }
    let(:definition) { DynamicActiveModel::Rails::DatabaseDefinition.new(:broken) }
    let(:loader) { described_class.new(definition, root) }

    before do
      FileUtils.mkdir_p(definition.extensions_path(root))
      File.write(File.join(definition.extensions_path(root), 'users.ext.rb'), "raise 'boom'\n")
      DynamicActiveModel::Rails::LazyNamespace.define(stub_const('BrokenDB', Module.new).name, loader)
    end

    after { FileUtils.rm_rf(root) }

    it 'raises and removes the models it had created' do
      expect { loader.load! }.to raise_error(RuntimeError, 'boom')
      expect(loader.loaded?).to be(false)
      expect(BrokenDB.const_defined?(:User, false)).to be(false)
      expect(BrokenDB.const_defined?(:DynamicAbstractBase, false)).to be(false)
    end
  end

  describe 'a database without an extensions folder' do
    let(:definition) { DynamicActiveModel::Rails::DatabaseDefinition.new(:plain) }
    let(:loader) { described_class.new(definition, Dir.tmpdir) }

    before { DynamicActiveModel::Rails::LazyNamespace.define(stub_const('PlainDB', Module.new).name, loader) }

    after { loader.reset! }

    it 'builds the models' do
      expect(loader.load!.models.map(&:table_name)).to include('users')
    end
  end

  describe 'definition options' do
    let(:root) { Dir.mktmpdir }
    let(:loader) { described_class.new(definition, root) }

    before { DynamicActiveModel::Rails::LazyNamespace.define(stub_const('PlainDB', Module.new).name, loader) }

    after do
      loader.reset!
      FileUtils.rm_rf(root)
    end

    context 'with include_tables' do
      let(:definition) do
        DynamicActiveModel::Rails::DatabaseDefinition.new(:plain).tap { |db| db.include_tables 'u*', 'posts' }
      end

      it 'models only the included tables, expanding wildcards' do
        expect(loader.load!.models.map(&:table_name)).to contain_exactly('users', 'posts')
      end
    end

    context 'with foreign_key_constraints' do
      let(:definition) do
        DynamicActiveModel::Rails::DatabaseDefinition.new(:plain, foreign_key_constraints: true)
                                                     .tap { |db| db.include_tables 'users', 'reviews' }
      end

      before do
        DummySchema.execute(:primary, <<~SQL)
          CREATE TABLE reviews (id INTEGER PRIMARY KEY, reviewer_id INTEGER, FOREIGN KEY (reviewer_id) REFERENCES users(id))
        SQL
      end

      after { DummySchema.execute(:primary, 'DROP TABLE IF EXISTS reviews') }

      it 'relates columns through constraints' do
        loader.load!
        expect(PlainDB::Review.reflect_on_association(:reviewer).klass).to eq(PlainDB::User)
      end
    end

    context 'with has_many_through' do
      let(:definition) do
        DynamicActiveModel::Rails::DatabaseDefinition.new(:plain, has_many_through: true)
                                                     .tap { |db| db.include_tables 'users', 'posts', 'post_editors' }
      end

      before do
        DummySchema.execute(:primary, <<~SQL)
          CREATE TABLE post_editors (id INTEGER PRIMARY KEY, post_id INTEGER, user_id INTEGER);
          CREATE UNIQUE INDEX index_post_editors_on_post_id_and_user_id ON post_editors (post_id, user_id);
        SQL
      end

      after { DummySchema.execute(:primary, 'DROP TABLE IF EXISTS post_editors') }

      it 'adds has_many :through across join models' do
        loader.load!
        expect(PlainDB::Post.reflect_on_association(:users).options).to eq(through: :post_editors, source: :user)
      end
    end

    context 'with a custom extensions_path and suffix' do
      let(:definition) do
        DynamicActiveModel::Rails::DatabaseDefinition.new(:plain, extensions_path: 'ext', extensions_suffix: '.model.rb')
      end

      before do
        FileUtils.mkdir_p(File.join(root, 'ext'))
        File.write(File.join(root, 'ext', 'users.model.rb'), "update_model { def custom_ext? = true }\n")
        File.write(File.join(root, 'ext', 'posts.ext.rb'), "raise 'wrong suffix applied'\n")
      end

      it 'applies only files with the suffix from that directory' do
        loader.load!
        expect(PlainDB::User.new.custom_ext?).to be(true)
      end
    end

    context 'with a custom extensions_path that does not exist' do
      let(:definition) { DynamicActiveModel::Rails::DatabaseDefinition.new(:plain, extensions_path: 'missing') }

      it 'raises and leaves nothing built' do
        expect { loader.load! }.to raise_error(DynamicActiveModel::Error, %r{extensions_path .*/missing for PlainDB})
        expect(loader.loaded?).to be(false)
        expect(PlainDB.const_defined?(:User, false)).to be(false)
      end
    end
  end

  describe 'load hooks' do
    it 'runs the database load hook on every build' do
      expect(AppDB::User.load_hook_ran?).to be(true)
      AppDB.dynamic_active_model_loader.reset!
      expect(AppDB::User.load_hook_ran?).to be(true)
    end
  end

  describe '#reset!' do
    let(:loader) { AppDB.dynamic_active_model_loader }

    it 'removes the models so the next load rebuilds them' do
      user = AppDB::User
      loader.reset!
      expect(AppDB.const_defined?(:User, false)).to be(false)
      expect(AppDB::User).not_to equal(user)
    end

    it 'clears the schema cache so rebuilt models see schema changes' do
      expect(AppDB::User.reflect_on_association(:posts)).to be_present
      # made outside a migration, so Rails' own schema cache clearing doesn't run
      DummySchema.execute(:primary, 'CREATE UNIQUE INDEX index_posts_on_user_id ON posts (user_id)')
      loader.reset!
      expect(AppDB::User.reflect_on_association(:post).macro).to eq(:has_one)
    ensure
      DummySchema.execute(:primary, 'DROP INDEX IF EXISTS index_posts_on_user_id')
      loader.reset!
    end

    it 'does nothing when not loaded' do
      expect { loader.reset! }.not_to raise_error
    end
  end
end
