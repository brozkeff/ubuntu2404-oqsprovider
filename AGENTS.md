# AGENTS.md

## Repository Purpose

This repo builds unofficial Ubuntu 24.04 `.deb` packages for
`open-quantum-safe/liboqs` and `open-quantum-safe/oqs-provider`.

Builds happen in GitHub Actions only. Do not build packages locally
unless the machine is Ubuntu 24.04 and the user explicitly asks for it.

## Project Rules

- Keep the repo small. Prefer boring shell, GitHub Actions, and existing
  upstream package metadata over custom packaging abstractions.
- Maintain `CHANGELOG.md` using Keep a Changelog 1.1 style. Future user-visible
  changes should update it.
- Read existing ADRs in `docs/decisions/` before changing build, release,
  licensing, or OpenSSL config behavior.
- Add or update ADRs for decisions that affect packaging strategy, release
  behavior, source provenance, licensing, or system config safety.
- Preserve EUPL 1.2 licensing for this repo's scripts and documentation.
  Upstream `liboqs` and `oqs-provider` retain their own licenses.
- Keep `scripts/enable-oqsprovider.sh` safe for interactive users:
  warn before editing `/etc/ssl/openssl.cnf`, back it up, validate before
  replacing it, and require `--unattended` for CI/CD.
- GitHub Actions builds must run only on tag pushes or manual
  `workflow_dispatch`.
- Do not enable `liboqs` `run_tests` until the first successful package build
  proves the workflow shape.
