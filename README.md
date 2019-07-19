[![Build Status](https://travis-ci.org/dougyouch/dynamic-active-model.svg?branch=master)](https://travis-ci.org/dougyouch/dynamic-active-model)

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

## Create Model Files
If you'd like to actually create the files for models, you can do so through

```bash
 dynamic-db-explorer --username root --adapter postgresql --host localhost --database rails_development --password password --create-class-files /path/to/folder/for/model/files
 ```
