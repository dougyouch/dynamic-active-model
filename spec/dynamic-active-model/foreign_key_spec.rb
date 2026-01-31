# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::ForeignKey do
  include_context 'database'

  describe '#generate_foreign_key' do
    subject { foreign_key.generate_foreign_key(table_name) }

    let(:table_name) { 'games' }

    it 'transform the table name to an id' do
      expect(subject).to eq('game_id')
    end
  end

  describe '#add' do
    before do
      foreign_key.add('super_user_id', 'super_user')
    end

    it 'returns all foreign_keys and there relationship_name' do
      expect(foreign_key.keys).to eq('user_id' => 'users', 'super_user_id' => 'super_user')
    end
  end
end
