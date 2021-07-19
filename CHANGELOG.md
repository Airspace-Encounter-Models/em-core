# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project should adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2021-07-19

### Added

- `.gitattributes` added for repository management
- MATLAB software to parse aircraft registries
- MATLAB software to parse FAA airports shapefile
- MATLAB software to create spatial boundaries

### Changed

- MinGW support for downloading FAA NASR data from [@morgenm](https://github.com/morgenm)
- Improved performance of `msl2agl`
- `bootstrap.sh` and `setup.sh` checks for operating system
- `setup.sh` downloads GSHGG and more FAA data

### Fixed

- `readAirspace` now correctly parses SFC lower altitude
- Inline function declaration for `computeVerticalRate` now aligns with function name

## [1.0.0] - 2020-09-25

### Added

- Initial public release

[1.1.0]: https://github.com/Airspace-Encounter-Models/em-core/releases/tag/v1.1
[1.0.0]: https://github.com/Airspace-Encounter-Models/em-core/releases/tag/v1.0
