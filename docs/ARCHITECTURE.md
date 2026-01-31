# Architecture Overview

Dynamic Active Model automatically discovers database schemas and creates ActiveRecord models with relationships.

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              User Entry Points                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Explorer.explore()          Setup module DSL          dynamic-db-explorer  │
│  (one-call interface)        (declarative config)      (CLI tool)           │
└──────────────┬───────────────────────┬───────────────────────┬──────────────┘
               │                       │                       │
               ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                Database                                      │
│  - Table filtering (blacklist/whitelist)                                    │
│  - Model creation orchestration                                             │
│  - Model extension loading (.ext.rb files)                                  │
└──────────────┬───────────────────────────────────────────────┬──────────────┘
               │                                               │
               ▼                                               ▼
┌──────────────────────────────┐          ┌──────────────────────────────────┐
│           Factory            │          │          Associations            │
│  - Creates abstract base     │          │  - Detects foreign keys          │
│  - Establishes DB connection │          │  - Creates belongs_to            │
│  - Generates model classes   │          │  - Creates has_many/has_one      │
│  - Applies DangerousAttrs    │          │  - Detects join tables (HABTM)   │
└──────────────┬───────────────┘          └──────────────┬───────────────────┘
               │                                         │
               ▼                                         ▼
┌──────────────────────────────┐          ┌──────────────────────────────────┐
│   DangerousAttributesPatch   │          │          ForeignKey              │
│  - Ignores conflicting cols  │          │  - Tracks FK columns             │
│  - Protects boolean methods  │          │  - Manages relationship names    │
└──────────────────────────────┘          │  - Configurable ID suffix        │
                                          └──────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TemplateClassFile                                  │
│  - Generates static Ruby model files from discovered models                 │
│  - Outputs all associations with proper options                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Model Creation Flow

1. **Entry** - User calls `Explorer.explore()`, includes `Setup` module, or runs CLI
2. **Database** - Filters tables, iterates through schema
3. **Factory** - Creates abstract base class with isolated DB connection
4. **Factory** - Creates model class for each table, includes `DangerousAttributesPatch`
5. **Associations** - Analyzes column names for foreign key patterns (`*_id`)
6. **Associations** - Checks unique indexes to distinguish `has_one` vs `has_many`
7. **Associations** - Detects join tables (2 FK columns, no PK) for `has_and_belongs_to_many`

### Extension Loading Flow

1. **Database.update_all_models** - Scans directory for `.ext.rb` files
2. **ModelUpdater** - Wraps model for safe evaluation
3. **File contents** - Evaluated in model context via `class_eval`

## Key Design Decisions

### Isolated Database Connection
Factory creates a `DynamicAbstractBase` abstract class per namespace. This isolates dynamic models from the application's `ActiveRecord::Base`, allowing different databases and preventing connection conflicts.

### Automatic Relationship Detection
Associations uses column naming conventions (`*_id`) combined with database indexes to infer relationships:
- Foreign key column → `belongs_to`
- Unique index on FK → `has_one` (1:1 relationship)
- No unique index on FK → `has_many` (1:N relationship)
- Join table pattern → `has_and_belongs_to_many`

### Dangerous Attribute Protection
Models include `DangerousAttributesPatch` which adds conflicting columns (e.g., `class`, `type`) to `ignored_columns`. This prevents Ruby method conflicts while still allowing database access.

### Extension Pattern
Extensions use `.ext.rb` suffix and `update_model` DSL. File names match table names (not model names), enabling per-table customization without modifying generated code.

## Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| Explorer | One-call interface combining Database + Associations |
| Database | Model lifecycle, filtering, extension loading |
| Factory | Class creation, connection management |
| Associations | Relationship detection and creation |
| ForeignKey | FK naming conventions, custom mappings |
| DangerousAttributesPatch | Column conflict prevention |
| TemplateClassFile | Static file generation |
| Setup | Declarative DSL for module configuration |
