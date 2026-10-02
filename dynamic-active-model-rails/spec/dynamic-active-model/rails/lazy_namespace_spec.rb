# frozen_string_literal: true

RSpec.describe DynamicActiveModel::Rails::LazyNamespace do
  let(:loader) { AppDB.dynamic_active_model_loader }

  it 'does not build models until a constant is referenced' do
    expect(loader.loaded?).to be(false)
    expect(AppDB::User.table_name).to eq('users')
    expect(loader.loaded?).to be(true)
  end

  it 'raises NameError for a constant that is not a model' do
    expect { AppDB::Nope }.to raise_error(NameError, /AppDB::Nope/)
    expect(loader.loaded?).to be(true)
  end

  it 'raises NameError once loaded' do
    AppDB.database
    expect { AppDB::Nope }.to raise_error(NameError, /AppDB::Nope/)
  end

  it 'exposes the database and its models' do
    expect(AppDB.database).to be_a(DynamicActiveModel::Database)
    expect(AppDB.models.map(&:table_name)).to contain_exactly('users', 'posts')
  end

  describe '.define' do
    context 'when the module does not exist' do
      after { Object.send(:remove_const, :NewDB) } # rubocop:disable RSpec/RemoveConst -- define creates it

      it 'creates a top-level module' do
        expect(described_class.define('NewDB', loader)).to equal(NewDB)
        expect(NewDB.dynamic_active_model_loader).to equal(loader)
      end
    end

    it 'reuses a module that is already defined' do
      existing = stub_const('ExistingDB', Module.new)
      expect(described_class.define('ExistingDB', loader)).to equal(existing)
      expect(existing.dynamic_active_model_loader).to equal(loader)
    end
  end
end
