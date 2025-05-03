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
- Sets up `has_many` and `belongs_to` relationships
- Maps database relationships to ActiveRecord associations

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