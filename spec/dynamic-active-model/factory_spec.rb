# frozen_string_literal: true

require 'spec_helper'

describe DynamicActiveModel::Factory do
  include_context 'database'

  describe '#generate_class_name' do
    subject { factory.generate_class_name(table_name) }

    let(:table_name) { 'users' }
    let(:expected_class_name) { 'User' }

    it 'converts table name to class name' do
      expect(subject).to eq(expected_class_name)
    end

    context 'when table name starts with a digit' do
      let(:table_name) { '123_data' }

      it 'prepends N to the class name' do
        # classify singularizes: 123_data -> 123Datum
        expect(subject).to eq('N123Datum')
      end
    end

    context 'when table name starts with multiple digits' do
      let(:table_name) { '2024_reports' }

      it 'prepends N to the class name' do
        expect(subject).to eq('N2024Report')
      end
    end
  end

  describe '#base_class' do
    subject { factory.base_class }

    it 'use default name' do
      subject
      expect(base_module.const_defined?(:DynamicAbstractBase)).to be(true)
    end

    describe 'change name' do
      let(:base_class_name) { :Foo }

      it 'use specified name' do
        subject
        expect(base_module.const_defined?(:Foo)).to be(true)
        expect(base_module.const_defined?(:DynamicAbstractBase)).to be(false)
      end
    end

    context 'when base class already exists' do
      before do
        # Create a factory and call base_class to create the base class
        factory.base_class
      end

      it 'reuses the existing base class' do
        # Create a second factory with the same module
        second_factory = described_class.new(
          base_module,
          connection_options,
          base_class_name
        )
        # Should return the existing base class
        expect(second_factory.base_class).to eq(factory.base_class)
      end
    end
  end

  describe '#base_class with a parent class' do
    subject { factory.base_class }

    let(:factory) { described_class.new(base_module, connection_options, nil, parent_class: parent_class) }
    let(:parent_class) do
      base_module.const_set(:Parent, Class.new(ActiveRecord::Base) { self.abstract_class = true })
      base_module::Parent.tap { |kls| kls.establish_connection(DB_CONFIG) }
    end

    context 'without connection options' do
      let(:connection_options) { nil }

      it 'subclasses the parent class' do
        expect(subject.superclass).to eq(parent_class)
      end

      it "shares the parent class's connection pool" do
        expect(subject.connection_pool).to equal(parent_class.connection_pool)
      end

      it 'creates models that read through the shared connection' do
        expect(factory.create('users').column_names).to include('name')
      end
    end

    context 'with connection options' do
      let(:connection_options) { create_sqlite_database('CREATE TABLE widgets (id INTEGER PRIMARY KEY);') }

      it 'establishes its own connection' do
        expect(subject.connection_pool).not_to equal(parent_class.connection_pool)
        expect(subject.connection.tables).to eq(['widgets'])
      end
    end
  end

  describe '#reset!' do
    context 'when the factory defined the base class' do
      let!(:original_base_class) { factory.base_class }

      before { factory.reset! }

      it 'removes the base class constant' do
        expect(base_module.const_defined?(:DynamicAbstractBase, false)).to be(false)
      end

      it 'builds a new base class on next use' do
        expect(factory.base_class).not_to equal(original_base_class)
      end
    end

    context 'when the base class was defined elsewhere' do
      let!(:existing_base_class) do
        base_module.const_set(:DynamicAbstractBase, Class.new(ActiveRecord::Base) { self.abstract_class = true })
      end

      before do
        factory.base_class
        factory.reset!
      end

      it 'keeps the base class constant' do
        expect(base_module::DynamicAbstractBase).to equal(existing_base_class)
      end
    end
  end

  describe '#remove' do
    before { factory.remove(factory.create('users')) }

    it 'removes the model constant' do
      expect(base_module.const_defined?(:User, false)).to be(false)
    end
  end

  describe '#base_class=' do
    subject { factory.base_class }

    let(:new_base_class) do
      Class.new do
        def self.table_name; end

        def self.table_name=(name); end
      end
    end

    before do
      factory.base_class = new_base_class
    end

    it 'expects base class to be the specified class' do
      expect(base_module.const_defined?(:DynamicAbstractBase)).to be(false)
      expect(subject == new_base_class).to be(true)
    end
  end

  describe '#create' do
    subject { factory.create(table_name, class_name) }

    let(:table_name) { 'users' }
    let(:class_name) { nil }

    context 'when class already exists' do
      before do
        factory.create(table_name)
      end

      it 'returns the existing class without creating a new one' do
        existing_class = base_module.const_get(:User)
        expect(subject).to eq(existing_class)
      end
    end
  end

  describe '#creates' do
    subject { factory.create(table_name, class_name) }

    let(:table_name) { 'users' }
    let(:class_name) { nil }

    it 'creates a class based on the table name' do
      expect(base_module.const_defined?(:User)).to be(false)
      subject
      expect(base_module.const_defined?(:User)).to be(true)
    end

    describe 'change base class' do
      let(:new_base_class) do
        Class.new do
          def self.table_name; end

          def self.table_name=(name); end

          def self.attribute_names; end
        end
      end

      before do
        factory.base_class = new_base_class
      end

      it 'creates a class for the table and use the new base class' do
        expect(base_module.const_defined?(:User)).to be(false)
        subject
        expect(base_module.const_defined?(:User)).to be(true)
        expect(base_module.const_get(:User).new.is_a?(new_base_class)).to be(true)
      end
    end
  end

  describe '#create with a class name already used by another table' do
    let(:connection_options) do
      create_sqlite_database(<<~SQL)
        CREATE TABLE status (id INTEGER PRIMARY KEY);
        CREATE TABLE statuses (id INTEGER PRIMARY KEY);
      SQL
    end

    before do
      factory.create('status')
    end

    it 'raises ClassNameConflict naming both tables' do
      expect { factory.create('statuses') }
        .to raise_error(DynamicActiveModel::ClassNameConflict, /statuses.*Status.*status/)
    end

    it 'creates the model when given a distinct class name' do
      expect(factory.create('statuses', 'StatusList').table_name).to eq('statuses')
    end
  end

  describe '#create with a table named like a top-level constant' do
    let(:connection_options) { create_sqlite_database('CREATE TABLE strings (id INTEGER PRIMARY KEY);') }

    it 'creates a model in the base module instead of returning the top-level constant' do
      model = factory.create('strings')
      expect(model).not_to eq(String)
      expect(model.table_name).to eq('strings')
    end
  end

  describe '#create when the class name is used by a non-model constant' do
    before do
      base_module.const_set(:User, Module.new)
    end

    it 'raises ClassNameConflict' do
      expect { factory.create('users') }
        .to raise_error(DynamicActiveModel::ClassNameConflict, /already used by another constant/)
    end
  end
end
