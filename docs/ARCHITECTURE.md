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
- Sets up `has_many`, `belongs_to`, and `has_one` relationships
- Maps database relationships to ActiveRecord associations
- Detects unique constraints for `has_one` relationship inference
- Supports composite unique keys for relationship detection

The relationship detection process works as follows:

1. **Foreign Key Analysis**
   - Scans all tables for foreign key constraints
   - Identifies the referenced tables and columns
   - Determines relationship cardinality based on constraints

2. **Unique Constraint Detection**
   - Identifies columns with unique constraints
   - Detects composite unique keys
   - Maps unique constraints to potential `has_one` relationships

3. **Relationship Type Inference**
   - `belongs_to`: Created when a table has a foreign key column
   - `has_many`: Created when another table has a foreign key pointing to this table
   - `has_one`: Created when:
     - A foreign key has a unique constraint
     - A unique key is referenced by another table's foreign key
     - Composite unique keys are properly handled

Example of unique constraint detection:
```ruby
# Table: users
#   - email (unique constraint)
#   - username (unique constraint)
#   - (id, type) (composite unique constraint)

# Table: profiles
#   - user_email (foreign key to users.email)
#   - user_username (foreign key to users.username)
#   - user_id (foreign key to users.id)
#   - user_type (foreign key to users.type)

# Results in:
class User < ActiveRecord::Base
  has_one :profile_by_email, foreign_key: :user_email
  has_one :profile_by_username, foreign_key: :user_username
  has_one :profile_by_id_type, foreign_key: [:user_id, :user_type]
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