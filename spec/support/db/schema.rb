ActiveRecord::Schema.define(version: 20190712000000) do

  create_table "users", force: true do |t|
    t.string   "name"
  end

  create_table "companies", force: true do |t|
    t.string "name"
    t.integer "website_id"
    t.integer "company_website_id"
  end

  create_table "jobs", force: true do |t|
    t.string "title"
  end

  create_table "websites", force: true do |t|
    t.string "url"
  end

  create_table "employments", force: true do |t|
    t.integer "user_id"
    t.integer "job_id"
    t.integer "company_id"
    t.datetime "started_at"
    t.datetime "ended_at"
  end

  create_table "stats_employment_durations", force: true do |t|
    t.integer "employment_id"
    t.integer "duration"
  end

  create_table "stats_company_employments", force: true do |t|
    t.integer "company_id"
    t.integer "average_duration"
    t.integer "num_jobs"
    t.integer "total_employees_lifetime"
    t.integer "num_current_employees"
    t.integer "num_employees_for_current_year"
  end

  create_table "tmp_load_data_table", force: true do |t|
    t.string "junk"
  end
end
