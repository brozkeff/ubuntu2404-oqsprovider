---
status: Accepted
date: 2026-06-17
---

# Package OQS provider from pinned upstream releases

## Context and Problem Statement

Ubuntu 24.04 ships OpenSSL 3, but does not ship the Open Quantum Safe provider
as a ready-to-install package. Teward documented a working manual build flow for
`liboqs` and `oqs-provider`; this repository turns that flow into repeatable
GitHub Actions builds that publish unofficial `.deb` packages.

The repository must keep licensing clear, avoid local build
assumptions, and make OpenSSL configuration changes explicit because a bad
`/etc/ssl/openssl.cnf` can break system TLS tools.

## Decision Drivers

- Keep the repository small and auditable.
- Build only on Ubuntu 24.04, matching the target packages.
- Preserve upstream licensing and attribution.
- Make generated packages visibly unofficial brozkeff builds.
- Require deliberate opt-in before modifying OpenSSL config interactively.

## Considered Options

- Pin upstream release tags and clone them in CI.
- Vendor upstream sources or use git submodules.
- Patch package metadata heavily for custom Debian packaging.

## Decision Outcome

Chosen option: "Pin upstream release tags and clone them in CI", because it is
the smallest source-control surface for the first build. The workflow builds
`open-quantum-safe/liboqs` tag `0.15.0` and
`open-quantum-safe/oqs-provider` tag `0.11.0`, then repacks the generated Debian
packages with versions ending in `+brozkeff.YYYYMMDD.g<sha>`.

The repo scripts and documentation are licensed under EUPL 1.2. Upstream source
and packages keep their upstream licenses; release assets include source
tarballs and upstream license files for the pinned tags.

### Consequences

- [+] No vendored source or submodule update workflow is needed.
- [+] GitHub Actions is the single supported build environment.
- [+] Debian package versions clearly show they are unofficial brozkeff builds.
- [-] Upstream CPack output is still trusted as the package base.
- [-] Release source availability depends on upstream repositories and attached
  source tarballs; tag names are not immutable commit SHA pins.

### Confirmation

The workflow must install the rebuilt `.deb` files on an Ubuntu 24.04 runner,
run `scripts/enable-oqsprovider.sh --unattended`, and verify that
`openssl list -providers` reports both `default` and `oqsprovider`.

## More Information

The OpenSSL config script is interactive by default and requires
`--unattended` for CI/CD. Interactive users must see the risk warning and backup
path. The script validates the patched config before replacing the live file.
Reverting the config is done by restoring the printed backup over
`/etc/ssl/openssl.cnf` and rerunning `openssl list -providers`.
