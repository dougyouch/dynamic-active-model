# Changelog

## [0.8.0](https://github.com/dougyouch/dynamic-active-model/compare/v0.7.2...v0.8.0) (2026-10-01)


### Features

* add documentation for all classes ([37b0b2f](https://github.com/dougyouch/dynamic-active-model/commit/37b0b2f23268e6ee73f135ee2d33828ea9469160))
* addec class_name for has_and_belongs_to_many, add specs for TemplateClassFile ([af7a5b5](https://github.com/dougyouch/dynamic-active-model/commit/af7a5b55590241ac034a9e9467f2aba7bcf54ea6))
* added irb and rdoc ([9059f69](https://github.com/dougyouch/dynamic-active-model/commit/9059f69af4fc56a4d943b86164ed5f55d435bd50))
* added note about extenstion file names ([952c40c](https://github.com/dougyouch/dynamic-active-model/commit/952c40ca807b9c84741db9cc16f36a7e845eba72))
* added support for has_and_belongs_to_many ([16925c3](https://github.com/dougyouch/dynamic-active-model/commit/16925c3b64c749c714c4594132f9c76d47e457a3))
* added update_all_models ([1366684](https://github.com/dougyouch/dynamic-active-model/commit/1366684a9a1aec3be1730ddeceb7ad5b54eb72f3))
* adding retry logic ([dcf1240](https://github.com/dougyouch/dynamic-active-model/commit/dcf1240433711c298c5a60d0f9a06f757b08dd45))
* adding support for update_model to extend class abilities ([392f14f](https://github.com/dougyouch/dynamic-active-model/commit/392f14f54d9c2e83abf8a56fefb6584cface20c3))
* bump version ([14d527d](https://github.com/dougyouch/dynamic-active-model/commit/14d527d58ab744a21c904f81a578d798907e97e5))
* cache table indexes initially ([8529e03](https://github.com/dougyouch/dynamic-active-model/commit/8529e03547f72e9ca70cdba4b983bacca84d1c16))
* can configure model file extensions suffix ([87556cf](https://github.com/dougyouch/dynamic-active-model/commit/87556cff417cc11cde3dc20e5b67c7c96c9bccc5))
* enable ci ([5f89008](https://github.com/dougyouch/dynamic-active-model/commit/5f8900877a8fd592a98ba2c93b2bed118fd507ab))
* ensure index is unique, fix for has many relationship name for manually entered relations ([99a6391](https://github.com/dougyouch/dynamic-active-model/commit/99a6391cdcb246cf40357ed99b32a3da9772fabb))
* fix codeclimate setup ([16cc5c8](https://github.com/dougyouch/dynamic-active-model/commit/16cc5c89ddf1c1290f97bb4c5541add11c543eb8))
* if connection_options is set to a string, fetch connection options from active record configurations ([308cc5f](https://github.com/dougyouch/dynamic-active-model/commit/308cc5f71bd83666229092842aefc1b2100500d6))
* removed postgres setup ([8bfad2d](https://github.com/dougyouch/dynamic-active-model/commit/8bfad2d36636c268cb650cc5c0dea3a5e0e663da))
* removed unused fields ([066d6bf](https://github.com/dougyouch/dynamic-active-model/commit/066d6bf65d43ab30b7c1028a40997926c929a166))
* tested with latest ruby and activerecord ([4e498dd](https://github.com/dougyouch/dynamic-active-model/commit/4e498ddf53c143569fe81bc226013f1c9f14fda4))
* update docs about has_and_belongs_to_many ([e1d71f5](https://github.com/dougyouch/dynamic-active-model/commit/e1d71f5cec9c37ea88d0cb2dd483710b44412eb8))
* updated docs based on has_one support ([a8f7054](https://github.com/dougyouch/dynamic-active-model/commit/a8f705491b588b23bc52d315006294ca36a3b0e0))
* updated gemspec ([d583d75](https://github.com/dougyouch/dynamic-active-model/commit/d583d75e3dbea199de28c86cf7592942bb8810fe))
* updated github action ruby version ([5556e6d](https://github.com/dougyouch/dynamic-active-model/commit/5556e6d06b32dd7201df6cef9312a11eaf60bfe3))
* updated README ([f5472d3](https://github.com/dougyouch/dynamic-active-model/commit/f5472d3227dba3f345576c4be1a3227de6d8c422))
* updated README with how to configure the module to connect to the primary DB ([c4a0662](https://github.com/dougyouch/dynamic-active-model/commit/c4a0662539be77edc28d479503e7b5c62c7467c2))
* updated README with use in rails instructions ([2a40ad5](https://github.com/dougyouch/dynamic-active-model/commit/2a40ad5ef6dedc10d281a0b3f115ac9bf84305ba))
* updated README with use in rails instructions ([8401336](https://github.com/dougyouch/dynamic-active-model/commit/84013368cb4691296fac2d507ee76d9d48deb3ed))
* updated Setup logic removed setter methods ([6032f6e](https://github.com/dougyouch/dynamic-active-model/commit/6032f6e408edd9ff68a17c5b2a5186fdad630c6f))
* updates based on rubocop ([b9fca7c](https://github.com/dougyouch/dynamic-active-model/commit/b9fca7c96647a01318af015f50cdeccffeac626a))
* use a has_one relationship if the relationship has a unique index on the foreign key ([cfac41c](https://github.com/dougyouch/dynamic-active-model/commit/cfac41ce45270332a39c5c8c9fc21e5e1cacc386))
* use codecov-action@v5 ([fba3695](https://github.com/dougyouch/dynamic-active-model/commit/fba3695c81c056d1fcb905a458926e5e4e6499b8))
* working on a Setup module ([7d8c62b](https://github.com/dougyouch/dynamic-active-model/commit/7d8c62b17e786c3b37d9b999ee369642de57b0b3))
* wrap model updates in a separate class ([3f0c735](https://github.com/dougyouch/dynamic-active-model/commit/3f0c7359add7a3c17a90edb0e06123acf5f8a907))


### Bug Fixes

* eval on table model ([16d3e8d](https://github.com/dougyouch/dynamic-active-model/commit/16d3e8d74e5b384b73eb71ad8b39faf4c9dd7f67))
* fix coverage for github ([14c5c6b](https://github.com/dougyouch/dynamic-active-model/commit/14c5c6bb50fa52087a4e7aed49b12f5f1e22b463))
* fixed db connection for fetching indexes ([0b30f85](https://github.com/dougyouch/dynamic-active-model/commit/0b30f85cb865f0ee477854065e060ddb82505ba1))
* Gemfile.lock ([0df3720](https://github.com/dougyouch/dynamic-active-model/commit/0df372086a1b06b945ace98b1dfc6f62cd2979b5))
* instructions about file based instructions ([d50398e](https://github.com/dougyouch/dynamic-active-model/commit/d50398e431f410fe0aec3e3f658abfe90ab48df9))
* revert change to has many name ([a6522e5](https://github.com/dougyouch/dynamic-active-model/commit/a6522e5b01965f70bdde765d26162dfacdbc7d0c))
* **spec:** remove test causing HABTM constant redefinition warning ([7a389a1](https://github.com/dougyouch/dynamic-active-model/commit/7a389a136a7936f5fa3d54838d69e6ea1e1d61dc))
* updated instance_eval with file and lineno ([bbe64b6](https://github.com/dougyouch/dynamic-active-model/commit/bbe64b6755c59192dfa238f4446f11db9d6f5ab5))
* updated instance_eval with file and lineno ([2d5dc6c](https://github.com/dougyouch/dynamic-active-model/commit/2d5dc6ca956fae49a90a998c1583dbb8303bb419))
