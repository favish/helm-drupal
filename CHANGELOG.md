# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2023-09-22
### Changed
- Add Blackfire to PHP deployment

## [2.2.2] - 2022-06-28
### Changed
- PHP bumps to favish/php-fpm:2.0.0 and favish/php-fpm-xdebug:2.0.0

## [2.1.0] - 2022-06-28
### Changed
- Removed cloud command pod.

## [2.0.2] - 2022-05-22
### Changed
- Also needed to update the cloud command pod mounts.

## [2.0.1] - 2022-05-22
### Changed
- That did not work so lets make individual mounts for the subpaths instead. 

## [2.0.0] - 2022-05-22
### Changed
- Subpaths don't work on WSL2 for HostPath mounted volumes. In order to support WSL based development we need to either 
  mount the whole application directory or we need to individually make volumes for each of these previous subpaths.

## [1.0.3] - 2021-11-19
### Changed
- Made FQDN value, extraVolumes and extraVolumeMounts top-level properties.

## [1.0.2] - 2021-11-19
### Changed
- Work out package management kinks.

## [1.0.0] - 2021-11-18
### Added
- Initial release.
