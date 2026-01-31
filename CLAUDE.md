# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake spec

# Run a single test file
bundle exec rspec spec/dynamic-active-model/database_spec.rb

# Run a specific test by line number
bundle exec rspec spec/dynamic-active-model/database_spec.rb:42

# Run linter
bundle exec rubocop

# Run linter with auto-fix
bundle exec rubocop -a
```

## Architecture Overview

Dynamic Active Model is a Ruby gem that automatically discovers database schemas and creates ActiveRecord models with relationships. It requires Ruby 3.0+ and ActiveRecord 4+.

### Core Components

**Explorer** (`lib/dynamic-active-model/explorer.rb`) - High-level entry point that orchestrates model creation and relationship building. Call `DynamicActiveModel::Explorer.explore(module, db_config)` for the simplest usage.

**Database** (`lib/dynamic-active-model/database.rb`) - Manages model creation with table filtering (blacklist/whitelist). Provides `skip_table`, `include_table`, and `update_model` methods for customization.

**Factory** (`lib/dynamic-active-model/factory.rb`) - Creates ActiveRecord model classes. Generates an abstract base class (`DynamicAbstractBase`) with its own database connection, keeping dynamic models isolated from the main `ActiveRecord::Base`.

**Associations** (`lib/dynamic-active-model/associations.rb`) - Automatically detects and creates relationships:
- `belongs_to` from foreign key columns
- `has_many` / `has_one` based on unique index presence
- `has_and_belongs_to_many` for join tables (2 columns, both foreign keys, no primary key)

**ForeignKey** (`lib/dynamic-active-model/foreign_key.rb`) - Tracks foreign key columns and their relationship names. Default suffix is `_id` but can be customized via `ForeignKey.id_suffix=`.

**Setup** (`lib/dynamic-active-model/setup.rb`) - DSL module for declarative configuration. Include in a module to get `connection_options`, `skip_tables`, `extensions_path`, and `create_models!` methods.

### Model Extension Pattern

Models can be extended via `.ext.rb` files based on table name (not model name):
```ruby
# users.ext.rb for the users table
update_model do
  def full_name
    "#{first_name} #{last_name}"
  end
end
```

### CLI Tool

`bin/dynamic-db-explorer` - Interactive database exploration tool. Can also generate model files with `--create-class-files DIR`.

### Test Environment

Tests use SQLite with schema defined in `spec/support/db/schema.rb`. The shared context 'database' in `spec/spec_helper.rb` creates isolated modules for each test to avoid constant collision.

## Code Commits

Format using angular formatting:
```
<type>(<scope>): <short summary>
```
- **type**: build|ci|docs|feat|fix|perf|refactor|test
- **scope**: The feature or component of the service we're working on
- **summary**: Summary in present tense. Not capitalized. No period at the end.

## Documentation Maintenance

When modifying the codebase, keep documentation in sync:
- **ARCHITECTURE.md** - Update when adding/removing classes, changing component relationships, or altering data flow patterns
- **README.md** - Update when adding new features, changing public APIs, or modifying usage examples
- **Code comments** - Update inline documentation when changing method signatures or behavior
