# frozen_string_literal: true

# Portable SQL (SQLite, PostgreSQL, MySQL) exercising has_many :through detection.
HAS_MANY_THROUGH_SCHEMA = <<~SQL
  CREATE TABLE users (id INTEGER PRIMARY KEY, name VARCHAR(255), teams VARCHAR(255));
  CREATE TABLE roles (id INTEGER PRIMARY KEY, name VARCHAR(255));
  CREATE TABLE teams (id INTEGER PRIMARY KEY, name VARCHAR(255));
  CREATE TABLE user_roles (id INTEGER PRIMARY KEY, user_id INTEGER, role_id INTEGER, created_by_id INTEGER, created_at TIMESTAMP);
  CREATE UNIQUE INDEX index_user_roles_on_user_id_and_role_id ON user_roles (user_id, role_id);
  CREATE TABLE team_members (id INTEGER PRIMARY KEY, user_id INTEGER, team_id INTEGER);
  CREATE UNIQUE INDEX index_team_members_on_user_id_and_team_id ON team_members (user_id, team_id);
  CREATE TABLE assignments (id INTEGER PRIMARY KEY, user_id INTEGER, role_id INTEGER, title VARCHAR(255));
  CREATE INDEX index_assignments_on_role_id ON assignments (role_id);
  CREATE UNIQUE INDEX index_assignments_on_user_id_and_title ON assignments (user_id, title);
  CREATE TABLE roles_teams (role_id INTEGER, team_id INTEGER);
SQL
