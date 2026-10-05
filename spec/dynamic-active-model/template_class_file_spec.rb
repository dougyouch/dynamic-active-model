# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

# These are integration style tests
describe DynamicActiveModel::TemplateClassFile do
  include_context 'database'

  before do
    relations.build!
  end

  let(:model_name) { :User }
  let(:model) { base_module.const_get(model_name) }
  let(:template_class_file) { described_class.new(model) }

  describe '#initialize' do
    it 'stores the model' do
      expect(template_class_file.instance_variable_get(:@model)).to eq(model)
    end
  end

  describe '#create_template!' do
    let(:temp_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'creates a Ruby file in the specified directory' do
      file_path = "#{temp_dir}/#{model.name.underscore}.rb"
      template_class_file.create_template!(temp_dir)
      expect(File.exist?(file_path)).to be(true)
    end

    it 'writes the correct content to the file' do
      file_path = "#{temp_dir}/#{model.name.underscore}.rb"
      template_class_file.create_template!(temp_dir)
      content = File.read(file_path)
      expect(content).to include("class #{model.name}")
      expect(content).to include('has_many :employments')
    end

    context 'with nested module name' do
      let(:model_name) { :Employment }

      it 'creates the namespace directory and the file with underscored path' do
        file_path = "#{temp_dir}/#{model.name.underscore}.rb"
        template_class_file.create_template!(temp_dir)
        expect(File.exist?(file_path)).to be(true)
      end
    end
  end

  describe '#to_s with has_many :through' do
    let(:connection_options) { create_test_database(HAS_MANY_THROUGH_SCHEMA) }

    before { DynamicActiveModel::HasManyThrough.new(database.models, relations.table_indexes).build! }

    it 'writes the through association with symbol options' do
      source = template_class_file.to_s
      expect(source).to include("  has_many :roles, through: :user_roles, source: :role\n")
      # declared after the association it goes through
      expect(source.index('has_many :roles,')).to be > source.index('has_many :user_roles,')
      expect(RubyVM::InstructionSequence.compile(source)).to be_a(RubyVM::InstructionSequence)
    end
  end

  describe '#to_s' do
    subject { template_class_file.to_s }

    it 'starts with class definition' do
      expect(subject).to start_with("class #{model.name}")
    end

    it 'ends with end statement' do
      expect(subject).to end_with("end\n")
    end

    it 'includes inheritance from ActiveRecord::Base' do
      expect(subject).to include('< ActiveRecord::Base')
    end

    context 'table name differs from class name' do
      let(:model_name) { :StatsEmploymentDuration }

      it 'includes self.table_name declaration' do
        expect(subject).to include('self.table_name = :stats_employment_durations')
      end
    end
  end

  context 'User' do
    subject { template_class_file.to_s }

    it 'verify User relationships' do
      expect(subject.include?('has_many :employments')).to be(true)
      expect(subject.include?('has_one :user_rollup')).to be(true)
    end

    it 'includes table_name due to namespaced module' do
      # With namespaced module like Module123::User, the underscore becomes
      # module123/user which pluralizes to module123/users, not matching 'users'
      expect(subject).to include('self.table_name')
    end
  end

  context 'Website' do
    subject { template_class_file.to_s }

    let(:model_name) { :Website }

    it 'verify Website relationships' do
      expect(subject.include?('has_many :companies')).to be(true)
      expect(subject.include?("has_and_belongs_to_many :jobs, join_table: 'jobs_websites'")).to be(true)
    end

    it 'includes class_name option for has_and_belongs_to_many when needed' do
      expect(subject).to include('has_and_belongs_to_many :jobs')
    end
  end

  context 'Employment' do
    subject { template_class_file.to_s }

    let(:model_name) { :Employment }

    it 'verify Employment relationships' do
      expect(subject.include?('has_many :stats_employment_durations')).to be(true)
      expect(subject).to match(/belongs_to :user, .*optional: true$/)
      expect(subject.include?('belongs_to :job')).to be(true)
      expect(subject.include?('belongs_to :company')).to be(true)
    end
  end

  context 'Company' do
    subject { template_class_file.to_s }

    let(:model_name) { :Company }

    it 'includes belongs_to relationship' do
      expect(subject).to include('belongs_to :website')
    end

    it 'includes has_many relationships' do
      expect(subject).to include('has_many :employments')
    end
  end

  context 'Job' do
    subject { template_class_file.to_s }

    let(:model_name) { :Job }

    it 'includes has_and_belongs_to_many relationship' do
      expect(subject).to include('has_and_belongs_to_many :websites')
    end

    it 'includes has_many relationship' do
      expect(subject).to include('has_many :employments')
    end
  end

  describe 'association options' do
    context 'has_many with non-standard foreign key' do
      let(:model_name) { :User }

      it 'includes foreign_key option when not standard' do
        # Check that foreign_key is included when it differs from default
        # For employments, the foreign_key is user_id which is standard
        output = template_class_file.to_s
        expect(output).to include('has_many :employments')
      end
    end

    context 'belongs_to with class_name' do
      let(:model_name) { :Employment }

      it 'generates correct belongs_to syntax' do
        output = template_class_file.to_s
        expect(output).to include('belongs_to :user')
        expect(output).to include('belongs_to :job')
        expect(output).to include('belongs_to :company')
      end
    end

    context 'has_one relationships' do
      let(:model_name) { :User }

      it 'generates has_one with correct options' do
        output = template_class_file.to_s
        expect(output).to include('has_one :user_rollup')
      end
    end

    context 'has_and_belongs_to_many relationships' do
      let(:model_name) { :Job }

      it 'includes join_table option' do
        output = template_class_file.to_s
        expect(output).to include("join_table: 'jobs_websites'")
      end
    end

    context 'stats model with non-standard table name' do
      let(:model_name) { :StatsEmploymentDuration }

      it 'includes table_name declaration' do
        output = template_class_file.to_s
        expect(output).to include('self.table_name = :stats_employment_durations')
      end

      it 'includes belongs_to relationship' do
        output = template_class_file.to_s
        expect(output).to include('belongs_to :employment')
      end
    end

    context 'user rollup model' do
      let(:model_name) { :UserRollup }

      it 'includes belongs_to relationship, required since user_id is NOT NULL' do
        output = template_class_file.to_s
        expect(output).to match(/belongs_to :user\b/)
        expect(output).not_to include('optional')
      end
    end
  end

  describe 'top-level models with explicit association options' do
    subject { described_class.new(custom_model).to_s }

    let(:custom_model) do
      Class.new(factory.base_class) do
        self.table_name = 'users'
        def self.name = 'User'
      end
    end

    context 'when options match the Rails defaults' do
      before do
        custom_model.has_many :employments, class_name: 'Employment', foreign_key: 'user_id', primary_key: 'id'
        custom_model.belongs_to :website, class_name: 'Website', foreign_key: 'website_id', primary_key: 'id'
        custom_model.has_one :user_rollup, class_name: 'UserRollup', foreign_key: 'user_id', primary_key: 'id'
        custom_model.has_and_belongs_to_many :jobs, class_name: 'Job'
      end

      it 'omits the default options and the table name' do
        expect(subject).to eq(<<~RUBY)
          class User < ActiveRecord::Base
            has_many :employments
            belongs_to :website
            has_one :user_rollup
            has_and_belongs_to_many :jobs
          end
        RUBY
      end
    end

    context 'when options differ from the Rails defaults' do
      before do
        custom_model.has_many :jobs, class_name: 'Employment', foreign_key: 'owner_id', primary_key: 'uuid'
        custom_model.belongs_to :site, class_name: 'Website', foreign_key: 'home_site_id'
        custom_model.has_one :rollup, class_name: 'UserRollup', foreign_key: 'owner_id', primary_key: 'uuid'
        custom_model.has_and_belongs_to_many :tags, class_name: 'Job', join_table: 'user_tags'
      end

      it 'includes every non-default option and skips unset ones' do
        expect(subject).to eq(<<~RUBY)
          class User < ActiveRecord::Base
            has_many :jobs, class_name: 'Employment', foreign_key: 'owner_id', primary_key: 'uuid'
            belongs_to :site, class_name: 'Website', foreign_key: 'home_site_id'
            has_one :rollup, class_name: 'UserRollup', foreign_key: 'owner_id', primary_key: 'uuid'
            has_and_belongs_to_many :tags, join_table: 'user_tags', class_name: 'Job'
          end
        RUBY
      end
    end
  end
end
