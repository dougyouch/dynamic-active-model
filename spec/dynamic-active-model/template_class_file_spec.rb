# frozen_string_literal: true

require 'spec_helper'

# These are integration style tests
describe DynamicActiveModel::TemplateClassFile do
  include_context 'database'

  before do
    relations.build!
  end

  let(:model_name) { :User }
  let(:model) { base_module.const_get(model_name) }
  let(:template_class_file) { DynamicActiveModel::TemplateClassFile.new(model) }

  context 'User' do
    subject { template_class_file.to_s }

    it 'verify User relationships' do
      expect(subject.include?('has_many :employments')).to eq(true)
      expect(subject.include?('has_one :user_rollup')).to eq(true)
    end
  end

  context 'Website' do
    subject { template_class_file.to_s }

    let(:model_name) { :Website }

    it 'verify Website relationships' do
      expect(subject.include?('has_many :companies')).to eq(true)
      expect(subject.include?("has_and_belongs_to_many :jobs, join_table: 'jobs_websites'")).to eq(true)
    end
  end

  context 'Employment' do
    subject { template_class_file.to_s }

    let(:model_name) { :Employment }

    it 'verify Employment relationships' do
      expect(subject.include?('has_many :stats_employment_durations')).to eq(true)
      expect(subject.include?('belongs_to :user')).to eq(true)
      expect(subject.include?('belongs_to :job')).to eq(true)
      expect(subject.include?('belongs_to :company')).to eq(true)
    end
  end
end
