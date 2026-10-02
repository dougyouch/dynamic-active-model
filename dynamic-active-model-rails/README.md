# dynamic-active-model-rails

Rails integration for [dynamic-active-model](https://github.com/dougyouch/dynamic-active-model). Declare your databases in one initializer, and their tables become ActiveRecord models in a `<Name>DB` namespace. Models are built on first use, rebuilt after migrations, and reloaded with the rest of the app in development.

Requires Rails 7.1+ and Ruby 3.2+.

## Installation

```ruby
# Gemfile
gem 'dynamic-active-model-rails'
```

`dynamic-active-model-rails` is released in lockstep with `dynamic-active-model` and pins the same version.

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
| `add_database :cars, module_name: 'Inventory'` | `Inventory` | `app/models/inventory/` |

The `cars_db` → `CarsDB` mapping is registered with the Rails autoloader only, not with the global inflector, so `'cars_db'.camelize` elsewhere in your app is unaffected.

### Options

| Option | Default | Description |
|---|---|---|
| `connection` (2nd argument) | `nil` | `nil` shares the parent class's connection. Otherwise it's passed to `establish_connection`: a database.yml entry name (Symbol), URL or hash. |
| `module_name:` | `"<Name>DB"` | Namespace override. |
| `parent_class:` | `'ApplicationRecord'` | Superclass of the generated abstract base class, given as a name so it can be reloaded. |

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

## Development

From this directory:

```bash
bundle install
bundle exec rspec
```

The specs boot a small Rails app in `spec/dummy` that has a primary and a `cars` SQLite database.
