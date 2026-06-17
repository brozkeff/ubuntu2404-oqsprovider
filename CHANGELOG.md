# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2026-06-17]

### Fixed

- Changed package metadata display in GitHub Actions to inspect `.deb` files
  one at a time after `dpkg -I dist/*.deb` failed on multiple packages.
- Fixed release publishing paths after downloaded workflow artifacts preserved
  their `dist/` and `sources/` directories.

### Added

- Initial Ubuntu 24.04 GitHub Actions build pipeline for unofficial `liboqs`
  and `oqs-provider` Debian packages.
- Release workflow for tag pushes, with manual workflow builds publishing
  artifacts by default and releases only when requested.
- Debian package repacking with `+brozkeff.YYYYMMDD.g<sha>` version suffixes.
- `scripts/enable-oqsprovider.sh` for backing up, patching, and verifying
  OpenSSL provider configuration.
- Initial ADR documenting pinned upstream tag builds, licensing, and OpenSSL
  config risks.
- README and adapted Teward build guide.
