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

    it 'does nothing when not loaded' do
      expect { loader.reset! }.not_to raise_error
    end
  end
end
