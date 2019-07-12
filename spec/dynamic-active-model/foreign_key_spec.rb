# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::ForeignKey do
  include_context 'database'

  context '#generate_foreign_key' do
    let(:table_name) { 'games' }
    subject { foreign_key.generate_foreign_key(table_name) }

    it 'transform the table name to an id' do
      expect(subject).to eq('game_id')
    end
  end

  context '#add' do
    before(:each) do
      foreign_key.add('super_user_id', 'super_user')
    end

    it 'returns all foreign_keys and there relationship_name' do
      expect(foreign_key.keys).to eq('user_id' => 'users', 'super_user_id' => 'super_user')
    end
  end
end
