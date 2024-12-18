# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2024-11-23

* Add usage example to README (#40)
* Format examples for easier readability and copying
* Support prepopulating query (#45)
* Allow customizing input separator. This will allow for pasting multiline items (#48)
* Support showing whitespace characters with placeholders (#48)
* Allow empty input (#48)
* Query field support for copy paste cut undo redo (#49)

## [1.3.1] - 2023-04-11

* Bump `MACOSX_DEPLOYMENT_TARGET` from `10.10` to `10.13` as Xcode 14.3+ only
  supports `10.13` and higher

## [1.3.0] - 2023-04-10

* Build color codes using snprintf for memory safety (#21)
* Increment bufferSize to account for NUL terminating byte (#22)
* Update README.md with related projects section (#24)
* Allow wraparound on up/down arrow (#26)
* Explicitly set xcodebuild configuration to Release (#29)
* Installation command has no prompt sign (#33)
* Adding prompt text to be displayed when query field is empty (#35)
* Fuzzy search output also going to stdout (#36)

## [1.2.1] - 2020-09-24

* Contains fix for illegal instruction

## [1.2.0] - 2020-08-14

* [Internal] Update project configuration for upcoming version 1.2 and Catalina (fb6677f)
* [Internal] Change default run configuration to debug (dc986e)
* Add support for colors that work in light and dark modes (66e0f51)

## [1.1.0] - 2020-06-02

* Added note about building and install docs

## [1.0.0] - 2015-03-18

* This is the initial release

[Unreleased]: https://github.com/chipsenkbeil/choose/compare/1.4.0...HEAD
[1.4.0]: https://github.com/chipsenkbeil/choose/compare/1.3.1...1.4.0
[1.3.1]: https://github.com/chipsenkbeil/choose/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/chipsenkbeil/choose/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/chipsenkbeil/choose/compare/1.2...1.2.1
[1.2.0]: https://github.com/chipsenkbeil/choose/compare/1.1...1.2
[1.1.0]: https://github.com/chipsenkbeil/choose/compare/1.0...1.1
[1.0.0]: https://github.com/chipsenkbeil/choose/releases/tag/1.0
