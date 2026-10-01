# Changelog

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
