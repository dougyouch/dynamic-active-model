# dynamic-active-model-rails

Rails integration for [dynamic-active-model](https://github.com/dougyouch/dynamic-active-model). Declare your databases in one initializer, and their tables become ActiveRecord models in a `<Name>DB` namespace. Models are built on first use, rebuilt after migrations, and reloaded with the rest of the app in development.

Requires Rails 7.1+ and Ruby 3.2+.

## Installation

```ruby
# Gemfile
gem 'dynamic-active-model-rails'
```

`dynamic-active-model-rails` is released in lockstep with `dynamic-active-model` and pins the same version.

## Generators

```bash
bin/rails generate dynamic_active_model:install                        # DB, app/models/db/
bin/rails generate dynamic_active_model:install grant_db               # GrantDB, app/models/grant_db/
bin/rails generate dynamic_active_model:database cars --connection cars
bin/rails generate dynamic_active_model:database cars --connection cars --replica cars_replica
bin/rails generate dynamic_active_model:extension grant_db users       # app/models/grant_db/users.ext.rb
```

- **`install [NAME]`** creates `config/initializers/dynamic_active_model.rb`, declaring the first database (default `db`), and its models folder.
- **`database NAME`** adds another `add_database` line to the initializer and creates the folder. It refuses a namespace the app already declares.
- **`extension DATABASE TABLE`** creates an extension file. `DATABASE` can be a name (`grant_db`) or a namespace (`GrantDB`). The generator uses the app's configuration, so a custom `extensions_path:` or `extensions_suffix:` is respected.

`--connection NAME` points the database at a `database.yml` entry. `--replica NAME` adds a reading role through `connects_to` and requires `--connection`. The generators warn if the current environment has no such entry. Without `--connection`, the database shares `ApplicationRecord`'s connection.

## Configuration

```ruby
# config/initializers/dynamic_active_model.rb
DynamicActiveModel::Rails.configure do |config|
  # No connection: models subclass ApplicationRecord and share its connection pool
  config.add_database :grant_db do |db|
    db.skip_tables 'versions'
  end

  # A Symbol names a database.yml entry; a URL string or config hash also works
  config.add_database :cars, :cars do |db|
    db.skip_tables 'legacy_*', /^tmp_/
    db.include_tables 'cars', 'makes', 'owner*'   # whitelist; default is every table
    db.foreign_key :cars, :owner_id, :owner
    db.table_class_name :status, 'StatusCode'
  end
end
```

```ruby
GrantDB::User.find(1)
CarsDB::Car.where(make: 'Honda')
CarsDB.models # => [CarsDB::Car, CarsDB::Make, ...]
```

`schema_migrations` and `ar_internal_metadata` are always skipped.

### Naming

Namespaces always end in `DB`, so a database's namespace never collides with an application class:

| Declaration | Namespace | Folder |
|---|---|---|
| `add_database :cars` | `CarsDB` | `app/models/cars_db/` |
| `add_database :grant_db` | `GrantDB` | `app/models/grant_db/` |
| `add_database :db` | `DB` | `app/models/db/` |
| `add_database :cars, module_name: 'Inventory'` | `Inventory` | `app/models/inventory/` |

The `cars_db` → `CarsDB` mapping is registered with the Rails autoloader only, not with the global inflector, so `'cars_db'.camelize` elsewhere in your app is unaffected.

### Options

| Option | Default | Description |
|---|---|---|
| `connection` (2nd argument) | `nil` | `nil` shares the parent class's connection. Otherwise it's passed to `establish_connection`: a database.yml entry name (Symbol), URL or hash. |
| `module_name:` | `"<Name>DB"` | Namespace override. |
| `parent_class:` | `'ApplicationRecord'` | Superclass of the generated abstract base class, given as a name so it can be reloaded. |
| `connects_to:` | `nil` | Roles for Rails multi-database support, such as `{ writing: :cars, reading: :cars_replica }`, or `connects_to`'s own arguments (`{ database: ..., shards: ... }`). Can't be combined with a `connection`. |
| `extensions_path:` | `app/models/<folder>` | Directory of extension files, absolute or relative to `Rails.root`. The default folder may be absent; a configured path must exist. |
| `extensions_suffix:` | `'.ext.rb'` | Suffix of extension files. The autoloader ignores files with this suffix. |

## Read Replicas

`connects_to:` registers the database's roles with Rails' multi-database support:

```ruby
config.add_database :cars, connects_to: { writing: :cars, reading: :cars_replica }
```

```yaml
# config/database.yml
production:
  cars:
    <<: *default
    database: cars
  cars_replica:
    <<: *default
    database: cars
    replica: true
```

Switch roles for one database through its namespace, or for every database with ActiveRecord:

```ruby
CarsDB.connected_to(role: :reading) { CarsDB::Car.count }       # only CarsDB
ActiveRecord::Base.connected_to(role: :reading) { ... }          # all databases with roles
```

Writes inside the reading role raise `ActiveRecord::ReadOnlyError`. Rails' automatic role switching (`config.active_record.database_selector`) works too. Shards pass through as well: `connects_to: { shards: { one: { writing: :cars_one } } }`.

A database that shares `ApplicationRecord`'s connection follows `ApplicationRecord`'s roles. `GrantDB.connected_to(...)` switches `ApplicationRecord`.

## Extending Models

Add one `<table_name>.ext.rb` file per table to the database's folder:

```ruby
# app/models/cars_db/cars.ext.rb
update_model do
  scope :by_make, ->(name) { joins(:make).where(makes: { name: name }) }

  def display_name
    "#{make.name} #{model}"
  end
end
```

The autoloader ignores `.ext.rb` files. Other `.rb` files in the folder autoload into the namespace as usual, so you can keep related classes next to the models:

```ruby
# app/models/cars_db/search.rb
module CarsDB
  class Search
    def self.for_make(name) = CarsDB::Car.by_make(name)
  end
end
```

## Load Hooks

Configuration that touches models at boot, like `has_paper_trail`, must be reapplied whenever the models are rebuilt. After every build, the gem runs an ActiveSupport load hook named after the database's folder. The block runs with the `DynamicActiveModel::Database` as `self`:

```ruby
# config/initializers/paper_trail.rb
ActiveSupport.on_load(:grant_db) do
  %w[users organizations].each { |table| get_model!(table).has_paper_trail }
end
```

Avoid `Rails.application.config.after_initialize { GrantDB.database... }`. It runs once, so models rebuilt after a reload or migration would lose that setup.

## Lifecycle

- **Lazy loading.** Nothing touches the database at boot. The first reference to a constant in a namespace builds that database's models. That's why `db:create`, `db:migrate` and `assets:precompile` don't need models to exist.
- **Eager loading.** With `config.eager_load` (production), every database's models are built at boot, along with the rest of the app.
- **Migrations.** After migrations run or a schema is loaded (`db:migrate`, `db:rollback`, `db:prepare`, `db:schema:load`, `maintain_test_schema!`), models are reset and rebuild on next use. That means `bin/rails db:prepare` followed by seeding works in one process.
- **Reloading.** In development, models are rebuilt whenever the app reloads, including after edits to `.ext.rb` files or to anything under `db/`, such as a migration rewriting `db/schema.rb`.

## Migrations

Migrations stay standard Rails. The gem reads the schema; it never owns it. For a secondary database, give its database.yml entry a `migrations_paths`:

```yaml
development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  cars:
    <<: *default
    database: storage/cars.sqlite3
    migrations_paths: db/cars_migrate
```

## Migrating from the Setup DSL

If your app followed the core gem's [manual setup](../docs/manual-rails-setup.md):

1. Replace `gem 'dynamic-active-model'` with `gem 'dynamic-active-model-rails'`.
2. Delete `app/models/db.rb`. Move its settings into an initializer:

   ```ruby
   # config/initializers/dynamic_active_model.rb
   DynamicActiveModel::Rails.configure do |config|
     config.add_database :db do |db|      # DB, app/models/db/
       db.skip_tables 'versions'
     end
   end
   ```

   | Setup DSL | Rails gem |
   |---|---|
   | `parent_class ApplicationRecord` | default (omit) |
   | `connection_options 'secondary'` | `add_database :db, :secondary` |
   | `extensions_path '...'` | default for `app/models/db/`; otherwise `extensions_path:` |
   | `extensions_suffix '.x.rb'` | `extensions_suffix:` |
   | `skip_tables [...]` / `skip_table` | `db.skip_tables` |
   | `foreign_key t, col, name` | `db.foreign_key t, col, name` |
   | `table_class_name t, name` | `db.table_class_name t, name` |

3. Remove the `DB` inflection and the `app/models/db` ignore from `config/application.rb`. The gem registers both.
4. Move setup that ran after `create_models!` into `ActiveSupport.on_load(:db) { ... }`.

`.ext.rb` files stay where they are.

## Development

From this directory:

```bash
bundle install
bundle exec rspec
```

The specs boot a small Rails app in `spec/dummy` that has a primary and a `cars` SQLite database.
