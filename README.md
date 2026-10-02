# Dynamic Active Model

[![CI](https://github.com/dougyouch/dynamic-active-model/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/dougyouch/dynamic-active-model/actions/workflows/ci.yml)
[![Coverage](https://raw.githubusercontent.com/dougyouch/dynamic-active-model/badges/coverage.svg)](https://github.com/dougyouch/dynamic-active-model/actions/workflows/ci.yml)

A Ruby gem that automatically discovers your database schema and creates corresponding ActiveRecord models with proper relationships. Perfect for rapid prototyping, database exploration, and working with legacy databases.

## Features

- **Automatic Schema Discovery**: Introspect database tables without manual configuration
- **Dynamic Model Creation**: Generate ActiveRecord models at runtime
- **Relationship Mapping**: Automatic `has_many`, `belongs_to`, `has_one`, and `has_and_belongs_to_many` detection
- **Model Extensions**: Customize models with `.ext.rb` files
- **Table Filtering**: Blacklist or whitelist tables using strings or regex patterns
- **Dangerous Attribute Protection**: Safe handling of column names that conflict with Ruby methods
- **Unique Constraint Detection**: Automatically uses `has_one` when foreign keys have unique indexes
- **Join Table Detection**: Recognizes HABTM join tables (two FK columns, no primary key)
- **Model File Generation**: Export discovered models to static Ruby files
- **CLI Tool**: Interactive database exploration via `dynamic-db-explorer`
- **Rails Integration**: The companion [`dynamic-active-model-rails`](dynamic-active-model-rails/) gem configures everything from one initializer

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynamic-active-model'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install dynamic-active-model
```

## Quick Start

### In-Memory Model Creation

```ruby
# Define your database model namespace
module DB; end

# Create models and relationships in one step
DynamicActiveModel::Explorer.explore(DB,
  username: 'root',
  adapter: 'postgresql',
  database: 'your_database',
  password: 'your_password'
)

# Start using your models
movie = DB::Movie.first
movie.name
movie.actors  # Automatically mapped relationship
```

### Using in a Rails Application

The easiest way is the companion gem [`dynamic-active-model-rails`](dynamic-active-model-rails/). It builds models lazily, rebuilds them after migrations, reloads them in development, and sets up the autoloader for you:

```ruby
# Gemfile
gem 'dynamic-active-model-rails'

# config/initializers/dynamic_active_model.rb
DynamicActiveModel::Rails.configure do |config|
  config.add_database :grant_db       # GrantDB::*, sharing ApplicationRecord's connection
  config.add_database :cars, :cars    # CarsDB::*, using the "cars" entry in database.yml
end
```

See its [README](dynamic-active-model-rails/README.md) for details. To wire things up by hand with the `Setup` DSL instead:

1. Configure Rails to handle the `DB` namespace correctly in `config/initializers/inflections.rb`:

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'DB'
end
```

2. Ignore the DB namespace for eager loading in `config/application.rb`:

```ruby
module YourApp
  class Application < Rails::Application
    Rails.autoloaders.main.ignore(
      "#{config.root}/app/models/db"
    )
  end
end
```

3. Create a base module file in `app/models/db.rb`:

```ruby
module DB
  include DynamicActiveModel::Setup

  # Share ApplicationRecord's connection pool
  parent_class ApplicationRecord
  # or connect to another database from database.yml:
  # connection_options 'secondary'

  # Set the path for auto-loading extension files
  extensions_path 'app/models/db'

  # Optionally skip tables you don't want to model
  # (schema_migrations and ar_internal_metadata are skipped automatically)
  skip_tables ['versions']

  # Create all models
  create_models!
end
```

4. Extend specific models with `.ext.rb` files in `app/models/db/`:

```ruby
# app/models/db/users.ext.rb
update_model do
  def full_name
    "#{first_name} #{last_name}"
  end

  def active?
    status == 'active'
  end
end
```

> **Note:** Extension files are based on the table name, not the model name. For a table named `user_profiles`, use `user_profiles.ext.rb`.

5. Use your models throughout the Rails application:

```ruby
class UsersController < ApplicationController
  def show
    @user = DB::User.find(params[:id])
    @full_name = @user.full_name
  end
end
```

### Generate Model Files

```bash
dynamic-db-explorer \
  --username root \
  --adapter postgresql \
  --database your_database \
  --password your_password \
  --create-class-files /path/to/models
```

## Advanced Usage

### Relationship Types

Dynamic Active Model automatically detects and creates four types of relationships:

| Relationship | Detection |
|--------------|-----------|
| `belongs_to` | Foreign key column exists |
| `has_many` | Another table references this table |
| `has_one` | Foreign key has a unique constraint |
| `has_and_belongs_to_many` | Join table with exactly two FK columns and no primary key |

Example join table detection:

```ruby
# Table: actors_movies (join table)
#   - actor_id (foreign key to actors.id)
#   - movie_id (foreign key to movies.id)
#   - No primary key

# Results in:
class Actor < ActiveRecord::Base
  has_and_belongs_to_many :movies
end

class Movie < ActiveRecord::Base
  has_and_belongs_to_many :actors
end
```

### Table Filtering

#### Blacklist Tables

```ruby
db = DynamicActiveModel::Database.new(DB, database_config)

db.skip_table 'temporary_data'
db.skip_table /^temp_/
db.skip_tables ['old_data', /^backup_/]

db.create_models!
```

#### Whitelist Tables

```ruby
db = DynamicActiveModel::Database.new(DB, database_config)

db.include_table 'users'
db.include_table /^customer_/
db.include_tables ['orders', 'products']

db.create_models!
```

ActiveRecord's internal tables (`schema_migrations`, `ar_internal_metadata`) are always skipped unless you name them in `include_table`. A whitelist pattern doesn't pull them in.

With `Explorer.explore` and the `Setup` DSL, `skip_tables` also accepts `*` wildcards that match whole table names (`'stats_*'`, `'*_backup'`).

### Custom Class Names

Model class names come from the singularized table name. When two tables map to the same class (e.g. `status` and `statuses`), `create_models!` raises `DynamicActiveModel::ClassNameConflict`. Give one of them its own class name:

```ruby
db.table_class_name 'statuses', 'StatusList'

# or with the Setup DSL
module DB
  include DynamicActiveModel::Setup
  table_class_name 'statuses', 'StatusList'
end

# or with Explorer
DynamicActiveModel::Explorer.explore(DB, database_config, [], {}, { 'statuses' => 'StatusList' })
```

### Extending Models

#### Inline Extensions

```ruby
db.update_model(:users) do
  attr_accessor :temp_password

  def full_name
    "#{first_name} #{last_name}"
  end
end
```

#### File-based Extensions

```ruby
# lib/db/users.ext.rb
update_model do
  attr_accessor :temp_password

  def full_name
    "#{first_name} #{last_name}"
  end
end

# Apply the extension
db.update_model(:users, 'lib/db/users.ext.rb')
```

#### Mass Update All Models

```ruby
db.update_all_models('lib/db')
```

### Database Connection

The gem supports all ActiveRecord database adapters:

```ruby
{
  adapter: 'postgresql',  # or 'mysql2', 'sqlite3', etc.
  host: 'localhost',
  database: 'your_database',
  username: 'your_username',
  password: 'your_password',
  port: 5432
}
```

To share an existing connection pool instead of opening a new one, pass a `parent_class`. The generated abstract base class subclasses it and inherits its connection when no connection options are given:

```ruby
DynamicActiveModel::Explorer.explore(DB, nil, parent_class: ApplicationRecord)
```

### Rebuilding Models

After a schema change, `reset!` removes the generated model constants (and the base class, if the gem defined it) so the models can be rebuilt:

```ruby
db.reset!
db.create_models!
```

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [API Documentation](https://www.rubydoc.info/gems/dynamic-active-model)

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dougyouch/dynamic-active-model.

## License

The gem is available as open source under the terms of the MIT License.
