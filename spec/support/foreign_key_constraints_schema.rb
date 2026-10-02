# frozen_string_literal: true

# Portable SQL (SQLite, PostgreSQL, MySQL) exercising foreign key constraint
# detection. Constraints are table-level (MySQL ignores inline REFERENCES) and
# each table is created after the tables it references.
FOREIGN_KEY_CONSTRAINTS_SCHEMA = <<~SQL
  CREATE TABLE users (id INTEGER PRIMARY KEY, legacy_id INTEGER UNIQUE, name VARCHAR(255));
  CREATE TABLE accounts (id INTEGER PRIMARY KEY);
  CREATE TABLE archivists (id INTEGER PRIMARY KEY);
  CREATE TABLE regions (country_id INTEGER, code INTEGER, PRIMARY KEY (country_id, code));
  CREATE TABLE posts (
    id INTEGER PRIMARY KEY, user_id INTEGER, author_id INTEGER, owner INTEGER, archivist_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (author_id) REFERENCES users(id),
    FOREIGN KEY (owner) REFERENCES users(id),
    FOREIGN KEY (archivist_id) REFERENCES archivists(id)
  );
  CREATE TABLE employees (id INTEGER PRIMARY KEY, manager_id INTEGER, FOREIGN KEY (manager_id) REFERENCES employees(id));
  CREATE TABLE profiles (id INTEGER PRIMARY KEY, account_id INTEGER, FOREIGN KEY (account_id) REFERENCES users(id));
  CREATE TABLE tickets (id INTEGER PRIMARY KEY, requester_id INTEGER, FOREIGN KEY (requester_id) REFERENCES users(legacy_id));
  CREATE TABLE stores (
    id INTEGER PRIMARY KEY, region_country_id INTEGER, region_code INTEGER,
    FOREIGN KEY (region_country_id, region_code) REFERENCES regions(country_id, code)
  );
SQL
