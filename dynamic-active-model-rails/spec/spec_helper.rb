# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  enable_coverage :branch
  root File.expand_path('..', __dir__)
  skip '/spec/'
end

ENV['RAILS_ENV'] = 'test'

require 'fileutils'
FileUtils.rm_f(Dir.glob(File.join(__dir__, 'dummy', 'tmp', '*.sqlite3*')))

$LOAD_PATH.unshift(__dir__)
require 'dummy/config/environment'
require 'support/dummy_schema'
require 'support/generator_helpers'

DummySchema.create!
ActiveRecord::Migration.verbose = false

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # specs that change the schema reset models; start every example from a clean slate
  config.after { DynamicActiveModel::Rails.reset! }
end
