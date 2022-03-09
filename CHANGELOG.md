# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project should adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `allcomb(varagin)` returns all combinations of inputted arrays. Function licensed under BSD-2 that permits redistribution and redistributed from [MathWorks File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/10064-allcomb-varargin).
- Run script, `RUN_mex` to compile MATLAB mex functions
- Moved `run_dynamics_fast` from em-pairing-uncor-importancesampling

### Changed

- Updated `run_dynamics_fast` with two additional inputs corresponding to dynamic limit constraints. Dynamic constraints were previously hardcoded constants in `run_dynamics_fast.c`
- Updated some variable names in `run_dynamics_fast` with a more consistent naming and style convention
- Replaced `ltln2val` with `geointerp` in `msl2agl` because MATLAB will remove `ltln2val` in the future
- Improved missing data handling in `msl2agl` by using `georasterinfo` and `standardizeMissing`
- Updated copyright year

### Fixed

- Fixed bug when allocating output buffer allocation size in `run_dynamics_fast.c` that was originally identified by @reliable-nranganathan

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
