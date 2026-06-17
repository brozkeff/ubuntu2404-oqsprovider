# Ubuntu 24.04 OQS provider packages

Unofficial Ubuntu 24.04 `.deb` builds for:

- `open-quantum-safe/liboqs` `0.15.0`
- `open-quantum-safe/oqs-provider` `0.11.0`

The build flow is adapted from Teward's Ubuntu Community Hub guide:
[How-To: 24.04 users get full post-quantum cryptography support in OpenSSL via oqsprovider](https://discourse.ubuntu.com/t/how-to-24-04-users-get-full-post-quantum-cryptography-support-in-openssl-via-oqsprovider/82362).

These packages are unofficial brozkeff builds. They are not produced or
supported by the Open Quantum Safe project.

## Releases

See [`CHANGELOG.md`](CHANGELOG.md) for project changes.

GitHub Actions builds only on tag pushes or manual `workflow_dispatch` runs.
It builds on `ubuntu-24.04`, installs the packages on the runner, enables the
provider, and checks:

```bash
openssl list -providers
```

Tag pushes publish a GitHub release automatically. Manual runs upload workflow
artifacts by default; set `publish_release` only when a manual run should also
create or update a release.

Release and workflow assets include:

- repacked `.deb` packages with versions like
  `0.15.0+brozkeff.20260617.gabcdef1`
- upstream source tarballs for the pinned tags
- upstream license files

## Enable oqsprovider

After installing both packages, run:

```bash
sudo scripts/enable-oqsprovider.sh
```

The script edits `/etc/ssl/openssl.cnf`. That can break OpenSSL-based tools if
the config becomes invalid, so interactive runs require confirmation and print a
backup path before writing. Use it on Ubuntu 24.04 hosts where the packages are
installed; avoid running it casually on production systems.

CI/CD must use:

```bash
sudo scripts/enable-oqsprovider.sh --unattended
```

## Revert OpenSSL config

The activation script prints the backup path, for example:

```text
Backup written: /etc/ssl/openssl.cnf.bak.20260617T120000Z
```

To revert:

```bash
sudo cp /etc/ssl/openssl.cnf.bak.20260617T120000Z /etc/ssl/openssl.cnf
openssl list -providers
```

Removing the Debian packages is separate:

```bash
sudo apt remove oqs-provider liboqs
```

## Build

Do not build this repository locally unless the machine is Ubuntu 24.04. The
intended build path is GitHub Actions.

Manual source-build notes are in [`docs/guide-by-teward.md`](docs/guide-by-teward.md).

## License

Repository scripts and documentation are licensed under EUPL 1.2. Upstream
`liboqs` and `oqs-provider` keep their own upstream licenses.
