# Manual Rails Setup

In a Rails app, use [`dynamic-active-model-rails`](../dynamic-active-model-rails/README.md). It does everything on this page for you, and also:

- rebuilds models after migrations, rollbacks and schema loads, in the same process
- runs an ActiveSupport load hook after every build, for setup like `has_paper_trail`
- supports several databases from one initializer

This page is for apps that can't take the Rails gem as a dependency. It wires up the core gem's `Setup` DSL by hand. Each step below was tested in a Rails 8.1 app.

1. In `config/application.rb`, map `app/models/db.rb` to `DB` and keep the autoloader out of the extension files:

```ruby
module YourApp
  class Application < Rails::Application
    # Zeitwerk would expect app/models/db.rb to define Db; scoping the inflection
    # to the autoloader leaves 'db_config'.camelize etc. unchanged elsewhere
    Rails.autoloaders.main.inflector.inflect('db' => 'DB')

    # .ext.rb files are applied by DynamicActiveModel, not autoloaded
    Rails.autoloaders.main.ignore("#{config.root}/app/models/db")
  end
end
```

2. Create the namespace in `app/models/db.rb`. Because the autoloader loads it, models are built on first reference to `DB` and rebuilt when the app reloads:

```ruby
module DB
  include DynamicActiveModel::Setup

  # Share ApplicationRecord's connection pool
  parent_class ApplicationRecord
  # or connect to another database from database.yml:
  # connection_options 'secondary'

  # Directory of extension files; use an absolute path, since a relative one
  # resolves against the process's working directory, not Rails.root
  extensions_path File.expand_path('db', __dir__)

  # Optionally skip tables you don't want to model
  # (schema_migrations and ar_internal_metadata are skipped automatically)
  skip_tables ['versions']

  # Create all models
  create_models!
end
```

3. Extend specific models with `.ext.rb` files in `app/models/db/`:

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

> **Note:** Extension files are based on the table name, not the model name. For a table named `user_profiles`, use `user_profiles.ext.rb`.

4. Use your models throughout the Rails application:

```ruby
class UsersController < ApplicationController
  def show
    @user = DB::User.find(params[:id])
    @full_name = @user.full_name
  end
end
```

## Limitations

- **Migrations:** tables created or changed by a migration aren't visible until the app reloads or restarts. Running `db:prepare` followed by seeds in a single process won't see new tables.
- **Boot-time setup:** setup that touches models (for example `has_paper_trail`) must go in `app/models/db.rb` after `create_models!`. It's re-run whenever the file is reloaded. Don't use `after_initialize`, which runs only once.
