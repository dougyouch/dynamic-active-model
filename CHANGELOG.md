# Changelog

## [1.3.0](https://github.com/dougyouch/dynamic-active-model/compare/v1.2.0...v1.3.0) (2026-10-03)


### Features

* **rails:** add dynamic_active_model:models and :export rake tasks ([e80f9d5](https://github.com/dougyouch/dynamic-active-model/commit/e80f9d5d60bb282751d283356ec70a88891de91a))
* **rails:** add dynamic_active_model:models and :export rake tasks ([34145bd](https://github.com/dougyouch/dynamic-active-model/commit/34145bd1af86f57848aca58d9ca862d3a8ecbbee))

## [1.2.0](https://github.com/dougyouch/dynamic-active-model/compare/v1.1.0...v1.2.0) (2026-10-03)


### Features

* **associations:** opt-in has_many :through across join models ([5c3ce3e](https://github.com/dougyouch/dynamic-active-model/commit/5c3ce3e245838d983ff4a9cad7b592263d823f71))
* opt-in has_many :through across join models ([5914ebe](https://github.com/dougyouch/dynamic-active-model/commit/5914ebe5785c1a61d04b07e4afe9c2627be3ecf2))
* **rails:** add_database has_many_through: option ([c1a9f76](https://github.com/dougyouch/dynamic-active-model/commit/c1a9f76864f1dfc4fc8bd4fb49935d9eecbd2132))


### Bug Fixes

* create the namespace directory for --create-class-files ([54e987f](https://github.com/dougyouch/dynamic-active-model/commit/54e987f9c14a682c67e1532e1ce82162fa15249c))
* **template:** create the namespace directory for class files ([9c970c1](https://github.com/dougyouch/dynamic-active-model/commit/9c970c13482b404b7dc5d6b99f6a2e0ce33a9576))

## [1.1.0](https://github.com/dougyouch/dynamic-active-model/compare/v1.0.0...v1.1.0) (2026-10-02)


### Features

* **associations:** opt-in detection from foreign key constraints ([4f7da12](https://github.com/dougyouch/dynamic-active-model/commit/4f7da12fab7dc6441212e6b07dcfd50a67ad2226))
* opt-in association detection from foreign key constraints ([f4cd4b1](https://github.com/dougyouch/dynamic-active-model/commit/f4cd4b15bb91fa7c2614f540b1fadcc4b16cce52))
* **rails:** add_database foreign_key_constraints: option ([3dee585](https://github.com/dougyouch/dynamic-active-model/commit/3dee585319f12536ec951cf3bd0969336dc7960d))

## [1.0.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.16.1...v1.0.0) (2026-10-02)


### ⚠ BREAKING CHANGES

* **setup:** connection_options no longer accepts a database.yml name as a String; pass a Symbol (connection_options :secondary), which establish_connection resolves for the current environment.
* dynamic-active-model now requires Ruby 3.2 or newer and ActiveRecord 7.1 or newer.

### Features

* require Ruby 3.2+ and ActiveRecord 7.1+ ([78c6be8](https://github.com/dougyouch/dynamic-active-model/commit/78c6be8fab81db15fe688deb35ecfb3127a97bff))
* **setup:** remove connection_options with a String database.yml name ([c0ac9e0](https://github.com/dougyouch/dynamic-active-model/commit/c0ac9e09e8d33a143a1b96a8b109fca8090352e7))

## [0.16.1](https://github.com/dougyouch/dynamic-active-model/compare/v0.16.0...v0.16.1) (2026-10-02)


### Bug Fixes

* **rails:** clear the schema cache through schema_reflection on Rails 7.1 ([9c7fbf7](https://github.com/dougyouch/dynamic-active-model/commit/9c7fbf7142c4cb4204c47308ba34b28bafd8cb33))

## [0.16.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.15.1...v0.16.0) (2026-10-02)


### Features

* deprecate connection_options with a String database.yml name ([cd2e75e](https://github.com/dougyouch/dynamic-active-model/commit/cd2e75e874de33beca0fa8f50e0222a26180b8e9))
* **rails:** register the core gem's deprecator with the app ([eee0304](https://github.com/dougyouch/dynamic-active-model/commit/eee0304cf5ecfa0f16057042430520d912688a7f))
* **setup:** deprecate connection_options with a String database.yml name ([6074649](https://github.com/dougyouch/dynamic-active-model/commit/60746492bdd0a0af182f257c92bc8ee8666be253))

## [0.15.1](https://github.com/dougyouch/dynamic-active-model/compare/v0.15.0...v0.15.1) (2026-10-02)


### Bug Fixes

* **rails:** clear a database's schema cache when resetting its models ([8667e06](https://github.com/dougyouch/dynamic-active-model/commit/8667e068ab24147c6466d811c0f27dc7c1e1c378))


### Performance Improvements

* **associations:** read indexes through the connection's schema cache ([c90dfe2](https://github.com/dougyouch/dynamic-active-model/commit/c90dfe286c606ea090d26ca7f4a457167697527b))
* build models from Rails' schema cache (indexes) ([aed2be1](https://github.com/dougyouch/dynamic-active-model/commit/aed2be14dcede8fb48d26e1478601f162e7209d5))

## [0.15.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.14.0...v0.15.0) (2026-10-02)


### Features

* **rails:** support connects_to for read replicas and shards ([c4b5eaa](https://github.com/dougyouch/dynamic-active-model/commit/c4b5eaa7b1c9b483677fac557e1e2c688654e12c))
* **rails:** support connects_to for read replicas and shards ([1881a26](https://github.com/dougyouch/dynamic-active-model/commit/1881a26cc53c3a0b5f15c91d29d9b9cb3545412e))

## [0.14.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.13.0...v0.14.0) (2026-10-02)


### Features

* **rails:** add install, database and extension generators ([6004307](https://github.com/dougyouch/dynamic-active-model/commit/6004307086b62f0f4467d2cc8fb2e606c4d9237c))
* **rails:** add install, database and extension generators ([b1080ec](https://github.com/dougyouch/dynamic-active-model/commit/b1080ec7f8f958b8d96518cb098fa71944891c1d))

## [0.13.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.12.0...v0.13.0) (2026-10-02)


### Features

* **rails:** add include_tables and extensions_path/suffix options ([209e8fb](https://github.com/dougyouch/dynamic-active-model/commit/209e8fb330dad9e9b64127e76d1cecee9a3cdfdb))
* **rails:** setup DSL parity and move manual Rails setup out of the README ([a3113a3](https://github.com/dougyouch/dynamic-active-model/commit/a3113a33a94632b6932121a74b0aee5332c6466c))


### Bug Fixes

* **rails:** map add_database :db to DB instead of DbDB ([1e4fdcf](https://github.com/dougyouch/dynamic-active-model/commit/1e4fdcf70fe24f3c60988575bee653fb28f5fd5c))

## [0.12.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.11.0...v0.12.0) (2026-10-02)


### Features

* **rails:** run an ActiveSupport load hook after each database build ([9f66fde](https://github.com/dougyouch/dynamic-active-model/commit/9f66fde3822080aef8dbef261753d4de0c6c70a5))
* **rails:** run an ActiveSupport load hook after each database build ([ebf0a20](https://github.com/dougyouch/dynamic-active-model/commit/ebf0a206b8a1017664b059d20aa29d311a284d3b))

## [0.11.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.10.0...v0.11.0) (2026-10-02)


### Features

* **rails:** add dynamic-active-model-rails companion gem ([ab93200](https://github.com/dougyouch/dynamic-active-model/commit/ab93200141350e6d6c749d3acba7d5da68fd6438))

## [0.10.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.9.1...v0.10.0) (2026-10-02)


### Features

* core changes for Rails integration (parent_class, reset!, skip internal tables) ([f88e08b](https://github.com/dougyouch/dynamic-active-model/commit/f88e08b809adb554ba529405191d411767678a70))
* **database:** add reset! to rebuild models after a schema change ([b2cae71](https://github.com/dougyouch/dynamic-active-model/commit/b2cae7197682917e329c7d9a95f23fb39bdeac74))
* **database:** skip ActiveRecord internal tables by default ([5786f00](https://github.com/dougyouch/dynamic-active-model/commit/5786f000cc0a2bf87ab71a68986c2b3ebff740ed))
* **factory:** add parent_class option to share an existing connection ([2129378](https://github.com/dougyouch/dynamic-active-model/commit/2129378f2084e5758899cb862ccb39c945779691))

## [0.9.1](https://github.com/dougyouch/dynamic-active-model/compare/v0.9.0...v0.9.1) (2026-10-01)


### Bug Fixes

* **template:** omit default habtm class_name and unset options in class files ([ae221ae](https://github.com/dougyouch/dynamic-active-model/commit/ae221ae243a1657a5aa7d6e1b4b1b72b37ea1373))

## [0.9.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.8.0...v0.9.0) (2026-10-01)


### Features

* **factory:** raise ClassNameConflict when tables share a class name ([585ffaf](https://github.com/dougyouch/dynamic-active-model/commit/585ffaf93d21fedd9a9307ee42add8afeb14c1c8))


### Bug Fixes

* **associations:** use the parent primary key for has_many and has_one ([7e484de](https://github.com/dougyouch/dynamic-active-model/commit/7e484de1c5a690b72e45ee8e36396d323932ec5b))
* **database:** make create_models! idempotent and return the models ([bb6b914](https://github.com/dougyouch/dynamic-active-model/commit/bb6b914b7e07a321660b7f59e25b40269d6beb84))

## [0.8.0](https://github.com/dougyouch/dynamic-active-model/compare/bbe64b6...v0.8.0) (2026-10-01)


### Features

* support and test against Ruby 4.0 ([a27a842](https://github.com/dougyouch/dynamic-active-model/commit/a27a842))
* expose `DynamicActiveModel::VERSION` ([e6bf097](https://github.com/dougyouch/dynamic-active-model/commit/e6bf097))


### Build

* remove unused development gems and the Travis setup ([a27a842](https://github.com/dougyouch/dynamic-active-model/commit/a27a842))
* replace Codecov with a GitHub-hosted coverage badge ([3b6033a](https://github.com/dougyouch/dynamic-active-model/commit/3b6033a))
* automate versioning and publishing with release-please ([e6bf097](https://github.com/dougyouch/dynamic-active-model/commit/e6bf097))
