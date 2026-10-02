# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::ForeignKeyConstraints do
  subject(:constraints) { described_class.new(database) }

  include_context 'database'

  let(:connection_options) { create_test_database(FOREIGN_KEY_CONSTRAINTS_SCHEMA) }

  before do
    database.skip_table 'archivists'
    database.create_models!
  end

  def model(table_name)
    database.get_model!(table_name)
  end

  it 'resolves a constraint the naming convention misses' do
    expect(constraints.find(model('posts'), 'author_id').to_h).to include(
      referenced_model: model('users'), primary_key: 'id', relationship_name: 'author'
    )
  end

  it 'names a conventional column like the convention does' do
    expect(constraints.find(model('posts'), 'user_id').relationship_name).to eq('users')
  end

  it 'resolves a self-reference' do
    expect(constraints.find(model('employees'), 'manager_id').referenced_model).to eq(model('employees'))
  end

  it 'keeps the referenced column when it is not the primary key' do
    expect(constraints.find(model('tickets'), 'requester_id').primary_key).to eq('legacy_id')
  end

  it 'skips columns without the id suffix' do
    expect(constraints.find(model('posts'), 'owner')).to be_nil
  end

  it 'skips constraints referencing a table without a model' do
    expect(constraints.find(model('posts'), 'archivist_id')).to be_nil
  end

  it 'skips composite constraints' do
    expect(constraints.find(model('stores'), 'region_country_id')).to be_nil
    expect(constraints.find(model('stores'), 'region_code')).to be_nil
  end

  it 'counts only usable constraints' do
    # posts.user_id, posts.author_id, employees.manager_id, profiles.account_id, tickets.requester_id
    expect(constraints.size).to eq(5)
  end
end
