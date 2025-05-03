[![Build Status](https://travis-ci.com/dougyouch/dynamic-active-model.svg?branch=master)](https://travis-ci.com/dougyouch/dynamic-active-model)
[![Maintainability](https://api.codeclimate.com/v1/badges/76f5bdfc2d2ca28514c6/maintainability)](https://codeclimate.com/github/dougyouch/dynamic-active-model/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/76f5bdfc2d2ca28514c6/test_coverage)](https://codeclimate.com/github/dougyouch/dynamic-active-model/test_coverage)

# Dynamic Active Model

Dynamic Active Model is a powerful Ruby gem that automatically discovers your database schema and creates corresponding ActiveRecord models with proper relationships. It's perfect for rapid prototyping, database exploration, and working with legacy databases.

## Features

- 🔍 Automatic database schema discovery
- 🏗️ Dynamic creation of ActiveRecord models
- 🔗 Automatic relationship mapping (`has_many`, `belongs_to`, and `has_one`)
- ⚡ In-memory model creation for quick exploration
- 📁 Physical model file generation
- 🛠️ Customizable model extensions
- ⚙️ Flexible table filtering (blacklist/whitelist)
- 🔒 Safe handling of dangerous attribute names
- 🔑 Automatic `has_one` detection based on unique constraints

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

Dynamic Active Model automatically detects and creates three types of relationships:

1. **`belongs_to`** - Created when a table has a foreign key column
2. **`has_many`** - Created when another table has a foreign key pointing to this table
3. **`has_one`** - Automatically detected when:
   - A table has a foreign key with a unique constraint
   - A table has a unique key constraint that another table references

Example of automatic `has_one` detection:

```ruby
# If users table has a unique constraint on email
# And profiles table has a foreign key to users.email
# Then the following relationships are automatically created:

class User < ActiveRecord::Base
  has_one :profile  # Automatically detected due to unique constraint
end

class Profile < ActiveRecord::Base
  belongs_to :user
end
```

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
