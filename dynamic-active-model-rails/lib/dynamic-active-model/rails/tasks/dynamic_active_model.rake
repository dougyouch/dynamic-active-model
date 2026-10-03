# frozen_string_literal: true

namespace :dynamic_active_model do
  desc 'List each declared database with its models and associations'
  task models: :environment do
    puts DynamicActiveModel::Rails::ModelReport.new(DynamicActiveModel::Rails.loaders)
  end

  desc 'Write a class file per model to DIR (default tmp/dynamic_active_model)'
  task export: :environment do
    dir = ENV.fetch('DIR') { Rails.root.join('tmp', 'dynamic_active_model').to_s }
    files = DynamicActiveModel::Rails::ModelExport.new(DynamicActiveModel::Rails.loaders).export!(dir)
    puts "Wrote #{files.size} class files to #{dir}"
  end
end
