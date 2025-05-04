[![Build Status](https://github.com/dougyouch/dynamic-active-model/workflows/CI/badge.svg)](https://github.com/dougyouch/dynamic-active-model/actions)
[![Code Coverage](https://codecov.io/gh/dougyouch/dynamic-active-model/branch/master/graph/badge.svg)](https://codecov.io/gh/dougyouch/dynamic-active-model)
[![Maintainability](https://api.codeclimate.com/v1/badges/76f5bdfc2d2ca28514c6/maintainability)](https://codeclimate.com/github/dougyouch/dynamic-active-model/maintainability)

# Dynamic Active Model

Dynamic Active Model is a powerful Ruby gem that automatically discovers your database schema and creates corresponding ActiveRecord models with proper relationships. It's perfect for rapid prototyping, database exploration, and working with legacy databases.

## Features

- 🔍 Automatic database schema discovery
- 🏗️ Dynamic creation of ActiveRecord models
- 🔗 Automatic relationship mapping (`has_many`, `belongs_to`, `has_one`, and `has_and_belongs_to_many`)
- ⚡ In-memory model creation for quick exploration
- 📁 Physical model file generation
- 🛠️ Customizable model extensions
- ⚙️ Flexible table filtering (blacklist/whitelist)
- 🔒 Safe handling of dangerous attribute names
- 🔑 Automatic `has_one` detection based on unique constraints
- 🤝 Automatic `has_and_belongs_to_many` detection for join tables

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
movie = DB::Movies.first
movie.name
movie.actors  # Automatically mapped relationship
```

### Using in a Rails Application

To use Dynamic Active Model in a Rails application, follow these steps:

1. First, configure Rails to handle the `DB` namespace correctly. Add this to `config/initializers/inflections.rb`:

```ruby
# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'DB'
end
```

2. To avoid eager loading issues, add this to `config/application.rb`:

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # ... other configuration ...

    # Ignore the DB namespace for eager loading
    Rails.autoloaders.main.ignore(
      "#{config.root}/app/models/db"
    )
  end
end
```

3. Create a base module file in `app/models/db.rb`:

```ruby
# app/models/db.rb
module DB
  include DynamicActiveModel::Setup

  # Use the primary database connection from database.yml
  connection_options 'primary'

  # Set the path for auto-loading extension files
  extensions_path 'app/models/db'

  # Optionally skip tables you don't want to model
  skip_tables ['schema_migrations', 'ar_internal_metadata']

  # Create all models
  create_models!
end
```

4. To extend specific models, create extension files in `app/models/db/` with the `.ext.rb` suffix:

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

> **Note:** Extension files are based on the table name, not the model name. For example, if you have a table named `user_profiles`, the extension file should be named `user_profiles.ext.rb`, even if the model is named `UserProfile`.

5. The extension files will be automatically loaded and applied to their respective models. For example, `users.ext.rb` will extend the `DB::User` model.

6. You can now use your models throughout your Rails application:

```ruby
# In a controller
class UsersController < ApplicationController
  def index
    @users = DB::User.all
  end

  def show
    @user = DB::User.find(params[:id])
    @full_name = @user.full_name  # Using the extended method
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

1. **`belongs_to`** - Created when a table has a foreign key column
2. **`has_many`** - Created when another table has a foreign key pointing to this table
3. **`has_one`** - Automatically detected when:
   - A table has a foreign key with a unique constraint
   - A table has a unique key constraint that another table references
4. **`has_and_belongs_to_many`** - Automatically detected when:
   - A join table exists with exactly two columns
   - Both columns are foreign keys to other tables
   - The join table has no primary key
   - The table name follows Rails conventions (alphabetically ordered plural model names)

Example of automatic `has_and_belongs_to_many` detection:

```ruby
# Table: actors
#   - id (primary key)
#   - name

# Table: movies
#   - id (primary key)
#   - title

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

Note: If a join table has additional columns or a primary key, it will be treated as a regular model with `has_many`/`belongs_to` relationships instead.

### Table Filtering

#### Blacklist (Skip) Tables

```ruby
db = DynamicActiveModel::Database.new(DB, database_config)

# Skip specific tables
db.skip_table 'temporary_data'
db.skip_table /^temp_/
db.skip_tables ['old_data', /^backup_/]

db.create_models!
```

#### Whitelist Tables

```ruby
db = DynamicActiveModel::Database.new(DB, database_config)

# Include only specific tables
db.include_table 'users'
db.include_table /^customer_/
db.include_tables ['orders', 'products']

db.create_models!
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
attr_accessor :temp_password

def full_name
  "#{first_name} #{last_name}"
end

# Apply the extension
db.update_model(:users, 'lib/db/users.ext.rb')
```

#### Mass Update All Models

```ruby
# Apply all .ext.rb files from a directory
db.update_all_models('lib/db')
```

## Configuration

### Database Connection

The gem supports all ActiveRecord database adapters. Here's a typical configuration:

```ruby
{
  adapter: 'postgresql',  # or 'mysql2', 'sqlite3', etc.
  host: 'localhost',
  database: 'your_database',
  username: 'your_username',
  password: 'your_password',
  port: 5432            # optional
}
```

## Best Practices

1. Always use a dedicated namespace for dynamic models to avoid conflicts
2. Use table filtering for large databases to improve performance
3. Keep model extensions modular and focused
4. Follow Ruby naming conventions in your extensions
5. Consider using whitelisting in production environments

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [API Documentation](https://www.rubydoc.info/gems/dynamic-active-model)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

## Support

If you discover any issues or have questions, please [create an issue](https://github.com/dougyouch/dynamic-active-model/issues).
