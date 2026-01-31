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
  end

  describe '#base_class' do
    subject { factory.base_class }

    it 'use default name' do
      subject
      expect(base_module.const_defined?(:DynamicAbstractBase)).to eq(true)
    end

    describe 'change name' do
      let(:base_class_name) { :Foo }

      it 'use specified name' do
        subject
        expect(base_module.const_defined?(:Foo)).to eq(true)
        expect(base_module.const_defined?(:DynamicAbstractBase)).to eq(false)
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
      expect(base_module.const_defined?(:DynamicAbstractBase)).to eq(false)
      expect(subject == new_base_class).to eq(true)
    end
  end

  describe '#creates' do
    subject { factory.create(table_name, class_name) }

    let(:table_name) { 'users' }
    let(:class_name) { nil }

    it 'creates a class based on the table name' do
      expect(base_module.const_defined?(:User)).to eq(false)
      subject
      expect(base_module.const_defined?(:User)).to eq(true)
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
        expect(base_module.const_defined?(:User)).to eq(false)
        subject
        expect(base_module.const_defined?(:User)).to eq(true)
        expect(base_module.const_get(:User).new.is_a?(new_base_class)).to eq(true)
      end
    end
  end
end
