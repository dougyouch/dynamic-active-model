ActiveRecord::Schema.define(version: 20_190_712_000_000) do
  create_table 'users', force: true do |t|
    t.string   'name'
  end

  create_table 'companies', force: true do |t|
    t.string 'name'
    t.string 'type'
    t.references :website, foreign_key: true
    t.integer :company_website_id
    t.foreign_key :website, column: :company_website_id
    t.text 'reload' # dangerous column name
    t.text 'save'
    t.text 'hash'
  end

  create_table 'jobs', force: true do |t|
    t.string 'title'
  end

  create_table 'websites', force: true do |t|
    t.string 'url'
  end

  create_table :jobs_websites, force: true, id: false do |t|
    t.belongs_to :job
    t.belongs_to :website
  end

  create_table 'employments', force: true do |t|
    t.references :user, foreign_key: true
    t.references :job, foreign_key: true
    t.references :company, foreign_key: true
    t.datetime 'started_at'
    t.datetime 'ended_at'
  end

  create_table 'stats_employment_durations', force: true do |t|
    t.references :employment, foreign_key: true
    t.integer 'duration'
  end

  create_table 'stats_company_employments', force: true do |t|
    t.references :company, foreign_key: true
    t.integer 'average_duration'
    t.integer 'num_jobs'
    t.integer 'total_employees_lifetime'
    t.integer 'num_current_employees'
    t.integer 'num_employees_for_current_year'
  end

  create_table 'tmp_load_data_table', force: true do |t|
    t.string 'junk'
  end

  create_table 'user_rollups' do |t|
    t.references :user, null: false, foreign_key: true, index: { unique: true }
    t.integer :total_websites
  end

  create_table 'employee_users' do |t|
    t.integer :employee_user_id, null: false
    t.foreign_key :users, column: :employee_user_id
    t.index :employee_user_id, unique: true
    t.boolean :super_user
  end
end
