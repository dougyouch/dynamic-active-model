# frozen_string_literal: true

require 'rake'
require 'stringio'
require 'tmpdir'

RSpec.describe 'dynamic_active_model rake tasks' do # rubocop:disable RSpec/DescribeClass
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? } # rubocop:disable RSpec/BeforeAfterAll

  def run_task(name)
    original = $stdout
    $stdout = StringIO.new
    Rake::Task[name].reenable
    Rake::Task[name].invoke
    $stdout.string
  ensure
    $stdout = original
  end

  it 'lists the models' do
    expect(run_task('dynamic_active_model:models')).to include("AppDB (shares ApplicationRecord's connection), 2 models")
  end

  it 'exports class files to DIR' do
    Dir.mktmpdir do |dir|
      output = with_env('DIR' => dir) { run_task('dynamic_active_model:export') }
      expect(output).to eq("Wrote 6 class files to #{dir}\n")
      expect(File).to exist(File.join(dir, 'cars_db/car.rb'))
    end
  end

  it 'exports to tmp/dynamic_active_model by default' do
    dir = Rails.root.join('tmp/dynamic_active_model').to_s
    expect(run_task('dynamic_active_model:export')).to eq("Wrote 6 class files to #{dir}\n")
  ensure
    FileUtils.rm_rf(dir)
  end

  def with_env(env)
    original = env.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    env.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end
end
