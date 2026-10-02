# Changelog

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
