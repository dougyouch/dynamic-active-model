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

## Rails Integration (dynamic-active-model-rails)

The companion gem lives in `dynamic-active-model-rails/`. It shares this repo's `VERSION`, and both gems are released together. It drives the core gem through `Database` and `Explorer`, and never subclasses its classes.

| Component | Responsibility |
|-----------|----------------|
| `DynamicActiveModel::Rails` | `configure`, plus `eager_load!` / `reset!` across all databases |
| Configuration | Collects `add_database` declarations |
| DatabaseDefinition | One database: connection, `<Name>DB` namespace, `<name>_db` folder, table settings |
| LazyNamespace | Extended into the namespace module; `const_missing` builds models on first reference; `connected_to` switches roles and shards via the connection-owning class |
| DatabaseLoader | Builds a database's models (synchronized), calls `connects_to` on the base class when configured, applies `.ext.rb` files, runs the `:<name>_db` ActiveSupport load hook, undoes a partial build |
| AutoloaderSetup | Zeitwerk-only `cars_db` → `CarsDB` inflection; ignores `.ext.rb` files |
| SchemaChangeHook | Prepended to `Migrator#migrate`/`#run` and `DatabaseTasks.load_schema` to reset models |
| Railtie | Registers eager loading, reset on code reload, and a watch on `db/` |
| Generators | `dynamic_active_model:install`, `:database`, `:extension`; naming comes from DatabaseDefinition, and `:extension` reads the app's configuration |

Lifecycle: `configure` (from an initializer) defines each namespace module and configures the autoloader before Zeitwerk is set up. Models are built on first constant reference, or at boot when eager loading. Code reloads and schema changes call `reset!`, which clears the database pool's schema cache and calls `Database#reset!`. The next reference rebuilds models against the current schema and the reloaded `ApplicationRecord`.

## Data Flow

### Model Creation Flow

1. **Entry** - User calls `Explorer.explore()`, includes `Setup` module, or runs CLI
2. **Database** - Filters tables (always skipping ActiveRecord's internal tables unless explicitly included), iterates through schema
3. **Factory** - Creates abstract base class, with an isolated DB connection or one inherited from `parent_class`
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
Factory creates a `DynamicAbstractBase` abstract class per namespace. This isolates dynamic models from the application's `ActiveRecord::Base`, allowing different databases and preventing connection conflicts. When a `parent_class` (e.g. `ApplicationRecord`) is given without connection options, the base class subclasses it and shares its connection pool instead of opening its own.

### Rebuilding
`Database#reset!` removes the generated model constants, and the base class when the factory defined it, so `create_models!` can rebuild against a changed schema. A reloader uses this to pick up migrations without restarting the process.

### Automatic Relationship Detection
Associations uses column naming conventions (`*_id`) combined with database indexes to infer relationships. It reads indexes through `connection.schema_cache`, so a Rails schema cache dump serves them without a query per table:
- Foreign key column → `belongs_to`
- Unique index on FK → `has_one` (1:1 relationship)
- No unique index on FK → `has_many` (1:N relationship)
- Join table pattern → `has_and_belongs_to_many`

With `foreign_key_constraints` on (`Associations#use_foreign_key_constraints!`), `ForeignKeyConstraints` reads `connection.foreign_keys` for every model and resolves each constraint to a model. A column with a constraint is related through it: its referenced model and primary key, self-references included. Other columns keep the naming convention. Composite constraints, columns without the id suffix, and constraints referencing a table without a model are skipped. Foreign keys aren't in Rails' schema cache, so this costs one query per table.

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
| ForeignKeyConstraints | Resolves the database's foreign key constraints to models (opt-in) |
| DangerousAttributesPatch | Column conflict prevention |
| TemplateClassFile | Static file generation |
| Setup | Declarative DSL for module configuration |
