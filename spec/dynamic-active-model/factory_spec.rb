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
end
