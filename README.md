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

Requires Ruby 3.3+ and ActiveRecord 7.1+. Tested in CI against Ruby 3.3–4.0 and ActiveRecord 7.1–8.1.

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

Use the companion gem [`dynamic-active-model-rails`](dynamic-active-model-rails/). It builds models lazily, rebuilds them after migrations, reloads them in development, and sets up the autoloader for you:

```ruby
# Gemfile
gem 'dynamic-active-model-rails'

# config/initializers/dynamic_active_model.rb
DynamicActiveModel::Rails.configure do |config|
  config.add_database :grant_db       # GrantDB::*, sharing ApplicationRecord's connection
  config.add_database :cars, :cars    # CarsDB::*, using the "cars" entry in database.yml
end
```

See its [README](dynamic-active-model-rails/README.md) for configuration, extension files, load hooks and migrations. If you can't use the Rails gem, [docs/manual-rails-setup.md](docs/manual-rails-setup.md) shows how to wire up the core gem by hand.

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

### has_many :through

Turn on `has_many_through` to add `has_many :through` associations across join models:

```ruby
DynamicActiveModel::Explorer.explore(DB, database_config, has_many_through: true)
# Setup DSL: has_many_through true
# CLI:       dynamic-db-explorer --has-many-through ...
```

A join model is a table with a primary key and a **unique index on exactly two columns**, each a `belongs_to` to a different model. That's how Rails apps usually mark one: `add_index :user_roles, [:user_id, :role_id], unique: true`. Other columns, such as timestamps, `created_by_id` or extra data, don't matter. For `user_roles`:

```ruby
User has_many :roles, through: :user_roles, source: :role
Role has_many :users, through: :user_roles, source: :user
```

The `has_many :user_roles` side already comes from the foreign keys. A name that's already taken on the model by an association, method or column is skipped. Tables without a primary key stay `has_and_belongs_to_many` join tables. Nested chains such as `User → roles → permissions` aren't generated; add those in an extension file.

### Foreign Key Constraints

By default, relationships come from column naming conventions (`user_id` → `users`). Turn on `foreign_key_constraints` to also use the database's foreign key constraints:

```ruby
DynamicActiveModel::Explorer.explore(DB, database_config, foreign_key_constraints: true)

# or with the Setup DSL
module DB
  include DynamicActiveModel::Setup
  connection_options database_config
  foreign_key_constraints true
  create_models!
end
```

```bash
dynamic-db-explorer --foreign-key-constraints ...
```

Constraints add relationships the naming convention can't infer:

| Constraint | Associations |
|---|---|
| `posts.author_id → users.id` | `Post belongs_to :author`, `User has_many :author_posts` |
| `employees.manager_id → employees.id` (self-reference) | `Employee belongs_to :manager`, `Employee has_many :manager_employees` |
| `tickets.requester_id → users.legacy_id` | `Ticket belongs_to :requester, primary_key: 'legacy_id'` |

Columns that follow the convention, such as `posts.user_id → users`, keep their usual names (`Post belongs_to :user`, `User has_many :posts`). A column with a constraint follows the constraint, even when its name suggests another table. Constraints on columns that don't end in the id suffix are skipped, because a `belongs_to` named after the column would hide the column itself. Composite constraints and constraints referencing a table without a model are skipped too.

Rails' schema cache doesn't store foreign keys, so reading constraints costs one query per table when models are built.

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

Connection options can be anything `establish_connection` accepts: a config hash, a URL, or a Symbol naming an entry in `ActiveRecord::Base.configurations` for the current environment (for example `connection_options :secondary` in the `Setup` DSL). Since 1.0, `connection_options` no longer accepts a database.yml name as a String. Pass a Symbol instead.

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
