# frozen_string_literal: true

require 'tmpdir'

RSpec.describe DynamicActiveModel::Rails::ModelExport do
  let(:dir) { Dir.mktmpdir }
  let(:loaders) { [AppDB.dynamic_active_model_loader] }

  after { FileUtils.rm_rf(dir) }

  it 'writes a class file per model under its namespace folder' do
    files = described_class.new(loaders).export!(dir)
    expect(files).to contain_exactly(File.join(dir, 'app_db/user.rb'), File.join(dir, 'app_db/post.rb'))
    expect(File.read(File.join(dir, 'app_db/post.rb'))).to include('class AppDB::Post < ActiveRecord::Base')
  end
end
