# Changelog

All notable changes to this package will be documented in this file.

The format is based on [Keep a Changelog][keepachangelog] and this project adheres to [Semantic Versioning][semver].

## v1.7.0

### Added

- The following environment variables are supported now: `MAX_CONNECTIONS`, `PROXY_PORT`, `SOCKS_PORT`

### Changed

- Entrypoint script (`bash`) replaced with [`mustpl`](https://github.com/tarampampam/mustpl)
- The result docker image `busybox:1.34.1-glibc` replaced with `busybox:stable-glibc`

### Removed

- Dockerfile healthcheck

## v1.6.0

### Added

- Possibility of changing DNS resolvers using environment variables `PRIMARY_RESOLVER` (primary) and `SECONDARY_RESOLVER` (secondary)

## v1.5.0

### Fixed

- Docker image building optimized

### Added

- Healthcheck in the dockerfile

## v1.4.0

### Changed

- 3proxy updated from `0.9.3` up to `0.9.4`

## v1.3.0

### Changed

- Logging in JSON format

## v1.2.0

### Changed

- 3proxy updated from `0.8.13` up to `0.9.3`

## v1.1.0

### Removed

- Environment variable `AUTH_REQUIRED` support

### Changed

- Proxy error pages a little bit styled

## v1.0.0

### Fixed

- Dockerfile and docker entry-point script cleanup

## v0.1.1

### Fixed

- Docker entry-point script clean

## v0.1.0

### Changed

- First project release

[keepachangelog]:https://keepachangelog.com/en/1.0.0/
[semver]:https://semver.org/spec/v2.0.0.html
