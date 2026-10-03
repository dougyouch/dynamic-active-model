# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::HasManyThrough do
  include_context 'database'

  let(:connection_options) { create_test_database(HAS_MANY_THROUGH_SCHEMA) }

  def model(table_name)
    database.get_model!(table_name)
  end

  def association(table_name, name)
    model(table_name).reflect_on_association(name)
  end

  before do
    database.create_models!
    relations.build!
  end

  context 'before it runs' do
    it 'leaves join models with has_many to the join only' do
      expect(association('users', :user_roles)).to be_present
      expect(association('users', :roles)).to be_nil
    end
  end

  context 'when built' do
    before { described_class.new(database.models, relations.table_indexes).build! }

    it 'adds has_many :through both ways across a join model' do
      expect(association('users', :roles).options).to eq(through: :user_roles, source: :role)
      expect(association('roles', :users).options).to eq(through: :user_roles, source: :user)
    end

    it 'loads records through the join model' do
      model('users').create!(id: 1, name: 'Ada')
      model('roles').create!(id: 1, name: 'admin')
      model('user_roles').create!(id: 1, user_id: 1, role_id: 1, created_by_id: 1)
      expect(model('users').find(1).roles.map(&:name)).to eq(['admin'])
      expect(model('roles').find(1).users.map(&:name)).to eq(['Ada'])
    end

    it 'skips a name that is already a column, keeping the other side' do
      expect(association('users', :teams)).to be_nil
      expect(association('teams', :users).options).to eq(through: :team_members, source: :user)
    end

    it 'ignores tables whose unique two-column index is not two foreign keys' do
      # assignments: unique (user_id, title) and a plain index on role_id
      through = %w[users roles].flat_map { |table| model(table).reflect_on_all_associations.map { |r| r.options[:through] } }
      expect(through).not_to include(:assignments)
    end

    it 'leaves tables without a primary key to has_and_belongs_to_many' do
      expect(association('roles', :teams).macro).to eq(:has_and_belongs_to_many)
    end
  end
end
