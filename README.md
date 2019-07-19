[![Build Status](https://travis-ci.com/dougyouch/dynamic-active-model.svg?branch=master)](https://travis-ci.com/dougyouch/dynamic-active-model)
[![Maintainability](https://api.codeclimate.com/v1/badges/76f5bdfc2d2ca28514c6/maintainability)](https://codeclimate.com/github/dougyouch/dynamic-active-model/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/76f5bdfc2d2ca28514c6/test_coverage)](https://codeclimate.com/github/dougyouch/dynamic-active-model/test_coverage)

# Dynamic Active Model - Automatic Database Discovery, Model Creation, and Relationship Mapping for Rails

Dynamic Active Model automatically reads a database, and maps the database classes to Active Record models. This includes defining relationships based on foreign keys. Currently, `has_many` and `belongs_to` relationships are supported. By default, Dynamic Active Model is best used for creating missing Active Record models, or exploring a database without having to create the models.

# Basic Usage

## Explore Database Models
This allows you to create Active Record models in memory.

```ruby
# Define your database model scope. This is neccesary to prevent conflicts.
module DB; end

# Intiialize models and relationships. This can be broken apart into separate calls if you'd like.
#
# Create the actual class models
#
#   db = DynamicActiveModel::Database.new(DB, username: 'root', adapter: 'postgresql', database: 'rails_development', password: 'password')
#   db.create_models!
#
# Create the relationships
#
#   relations = DynamicActiveModel::Associations.new(db)
#   relations.build!
#
# Instead, this combines both those methods into one
DynamicActiveModel::Explorer.explore(DB, username: 'root', adapter: 'postgresql', database: 'rails_development', password: 'password')

# find some model
movie = DB::Movies.first

# some attribute
movie.name

# some relationships
movie.actors
```

### Blacklist (Skip) Tables to Create Models For
You can blacklist tables to create models for, to ignore certain specific tables

```ruby
# initialize the database
db = DynamicActiveModel::Database.new(DB, username: 'root', adapter: 'postgresql', database: 'rails_development', password: 'password')

# skip a single table
db.skip_table 'actors'

# skip tables by regex
db.skip_table /^temp/

# skip multiple tables
db.skip_tables ['2018-01-01_temp', /^daily/]

db.create_models!
```

### Whitelist Tables to Create Models For
If you'd like to whitelist instead, that's also available.

```ruby
# initialize the database
db = DynamicActiveModel::Database.new(DB, username: 'root', adapter: 'postgresql', database: 'rails_development', password: 'password')

# include a single table
db.include_table 'actors'

# include tables by regex
db.include_table /^special/

# include multiple tables
db.include_tables ['movies', 'salaries']

db.create_models!
```

## Create Model Files
If you'd like to actually create the files for models, you can do so through

```bash
 dynamic-db-explorer --username root --adapter postgresql --host localhost --database rails_development --password password --create-class-files /path/to/folder/for/model/files
 ```
