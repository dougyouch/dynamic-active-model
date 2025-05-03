# Dynamic Active Model - Architecture Documentation

## Overview
Dynamic Active Model is a Ruby gem that provides automatic database discovery, model creation, and relationship mapping for Rails applications. It allows developers to dynamically create ActiveRecord models from existing database schemas without manually writing model classes.

## Core Components

### 1. Database (`DynamicActiveModel::Database`)
The Database class is responsible for:
- Connecting to the database using provided credentials
- Discovering database tables and their schemas
- Creating dynamic ActiveRecord model classes
- Managing table inclusion/exclusion lists
- Providing model update capabilities

### 2. Associations (`DynamicActiveModel::Associations`)
Handles the automatic discovery and setup of model relationships:
- Analyzes foreign key constraints
- Sets up `has_many`, `belongs_to`, `has_one`, and `has_and_belongs_to_many` relationships
- Maps database relationships to ActiveRecord associations
- Detects unique constraints for `has_one` relationship inference
- Supports composite unique keys for relationship detection
- Identifies join tables for `has_and_belongs_to_many` relationships

The relationship detection process works as follows:

1. **Foreign Key Analysis**
   - Scans all tables for foreign key constraints
   - Identifies the referenced tables and columns
   - Determines relationship cardinality based on constraints

2. **Join Table Detection**
   - Identifies potential join tables based on:
     - Table having exactly two columns
     - Both columns being foreign keys
     - No primary key present
     - Table name following Rails conventions (alphabetically ordered plural model names)
   - Validates join table structure:
     - Ensures no additional columns exist
     - Confirms foreign keys point to different tables
     - Verifies table naming convention compliance

3. **Unique Constraint Detection**
   - Identifies columns with unique constraints
   - Detects composite unique keys
   - Maps unique constraints to potential `has_one` relationships

4. **Relationship Type Inference**
   - `belongs_to`: Created when a table has a foreign key column
   - `has_many`: Created when another table has a foreign key pointing to this table
   - `has_one`: Created when:
     - A foreign key has a unique constraint
     - A unique key is referenced by another table's foreign key
     - Composite unique keys are properly handled
   - `has_and_belongs_to_many`: Created when:
     - A join table meets all strict criteria
     - Table name follows Rails naming conventions
     - No additional columns or primary key present

Example of join table detection:
```ruby
# Table: actors
#   - id (primary key)
#   - name

# Table: movies
#   - id (primary key)
#   - title

# Table: actors_movies (valid join table)
#   - actor_id (foreign key to actors.id)
#   - movie_id (foreign key to movies.id)
#   - No primary key

# Table: movies_actors (invalid join table - wrong naming order)
#   - movie_id (foreign key to movies.id)
#   - actor_id (foreign key to actors.id)
#   - No primary key

# Table: actor_movie_roles (invalid join table - additional columns)
#   - actor_id (foreign key to actors.id)
#   - movie_id (foreign key to movies.id)
#   - role (additional column)
#   - No primary key

# Results in:
class Actor < ActiveRecord::Base
  has_and_belongs_to_many :movies  # Only this relationship is created
end

class Movie < ActiveRecord::Base
  has_and_belongs_to_many :actors  # Only this relationship is created
end
```

### 3. Explorer (`DynamicActiveModel::Explorer`)
A high-level interface that combines Database and Associations functionality:
- Provides a single entry point for model discovery and relationship mapping
- Simplifies the initialization process

### 4. Factory (`DynamicActiveModel::Factory`)
Manages the creation of model classes:
- Creates new model classes within specified namespaces
- Handles model class naming and inheritance

### 5. Foreign Key (`DynamicActiveModel::ForeignKey`)
Manages foreign key relationships:
- Parses foreign key constraints
- Determines relationship types
- Provides metadata for association setup

### 6. Template Class File (`DynamicActiveModel::TemplateClassFile`)
Handles the generation of model class files:
- Creates physical Ruby files for models
- Manages file templates and generation
- Handles model extension inclusion

### 7. Setup (`DynamicActiveModel::Setup`)
Manages the setup process:
- Handles initialization configuration
- Manages database connection setup
- Coordinates component initialization

### 8. Dangerous Attributes Patch (`DynamicActiveModel::DangerousAttributesPatch`)
A safety feature that:
- Prevents conflicts with Ruby reserved words
- Handles potentially problematic column names
- Provides safe attribute access methods

## Flow of Operation

1. **Initialization**
   - Database connection is established
   - Table discovery is performed
   - Model classes are created in specified namespace

2. **Model Creation**
   - Tables are filtered based on inclusion/exclusion rules
   - Model classes are generated for each included table
   - Basic ActiveRecord configuration is applied

3. **Relationship Mapping**
   - Foreign keys are discovered
   - Relationships are analyzed
   - Association methods are defined

4. **Extension**
   - Models can be extended with custom functionality
   - Additional methods can be added via update_model
   - External extension files can be loaded

## Usage Patterns

### In-Memory Models
```ruby
module DB; end
DynamicActiveModel::Explorer.explore(DB, database_config)
```

### File Generation
```bash
dynamic-db-explorer --create-class-files /path/to/models
```

### Model Extension
```ruby
db.update_model(:table_name) do
  # Custom methods and attributes
end
```

## Best Practices

1. **Namespace Usage**
   - Always use a dedicated namespace for dynamic models
   - Avoid conflicts with existing application models

2. **Table Management**
   - Use table filtering to manage large databases
   - Consider using whitelisting for specific table sets

3. **Model Extensions**
   - Keep extensions modular and focused
   - Use separate files for complex extensions
   - Follow Ruby naming conventions

4. **Performance Considerations**
   - Be mindful of large database schemas
   - Use selective table inclusion when possible
   - Consider caching for production environments 