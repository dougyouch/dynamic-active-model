# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::ForeignKey do
  include_context 'database'

  describe '.id_suffix' do
    subject { described_class.id_suffix }

    it 'returns the default suffix' do
      expect(subject).to eq('_id')
    end

    context 'when custom suffix is set' do
      before do
        described_class.id_suffix = '_ref'
      end

      after do
        described_class.id_suffix = nil # Reset to default
      end

      it 'returns the custom suffix' do
        expect(subject).to eq('_ref')
      end
    end
  end

  describe '.id_suffix=' do
    after do
      described_class.id_suffix = nil # Reset to default
    end

    it 'sets a custom suffix' do
      described_class.id_suffix = '_fk'
      expect(described_class.id_suffix).to eq('_fk')
    end
  end

  describe '#initialize' do
    subject { described_class.new(model) }

    let(:model) { factory.create('users') }

    it 'sets the model' do
      expect(subject.model).to eq(model)
    end

    it 'initializes with the default foreign key' do
      expect(subject.keys).to include('user_id')
    end

    it 'sets the default relationship name from table name' do
      expect(subject.keys['user_id']).to eq('users')
    end
  end

  describe '#generate_foreign_key' do
    subject { foreign_key.generate_foreign_key(table_name) }

    let(:table_name) { 'games' }

    it 'transform the table name to an id' do
      expect(subject).to eq('game_id')
    end

    context 'with plural table name' do
      let(:table_name) { 'companies' }

      it 'singularizes the table name' do
        expect(subject).to eq('company_id')
      end
    end

    context 'with underscored table name' do
      let(:table_name) { 'user_profiles' }

      it 'handles underscored names correctly' do
        expect(subject).to eq('user_profile_id')
      end
    end

    context 'with custom id_suffix' do
      before do
        described_class.id_suffix = '_ref'
      end

      after do
        described_class.id_suffix = nil
      end

      it 'uses the custom suffix' do
        expect(subject).to eq('game_ref')
      end
    end
  end

  describe '#add' do
    before do
      foreign_key.add('super_user_id', 'super_user')
    end

    it 'returns all foreign_keys and there relationship_name' do
      expect(foreign_key.keys).to eq('user_id' => 'users', 'super_user_id' => 'super_user')
    end

    context 'without relationship name' do
      before do
        foreign_key.add('manager_id')
      end

      it 'uses the model table name as relationship name' do
        expect(foreign_key.keys['manager_id']).to eq('users')
      end
    end

    context 'with custom relationship name' do
      before do
        foreign_key.add('owner_id', 'owner')
      end

      it 'uses the specified relationship name' do
        expect(foreign_key.keys['owner_id']).to eq('owner')
      end
    end
  end

  describe '#model' do
    subject { foreign_key.model }

    it 'returns the associated model' do
      expect(subject.table_name).to eq('users')
    end
  end

  describe '#keys' do
    subject { foreign_key.keys }

    it 'returns a hash of foreign keys to relationship names' do
      expect(subject).to be_a(Hash)
    end

    it 'includes the default foreign key' do
      expect(subject).to have_key('user_id')
    end
  end
end
