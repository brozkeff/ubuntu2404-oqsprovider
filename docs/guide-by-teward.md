# Build guide adapted from Teward's OQS provider notes

This document adapts Teward's Ubuntu Community Hub guide for this repository's
GitHub Actions package build:
[How-To: 24.04 users get full post-quantum cryptography support in OpenSSL via oqsprovider](https://discourse.ubuntu.com/t/how-to-24-04-users-get-full-post-quantum-cryptography-support-in-openssl-via-oqsprovider/82362).

The original guide is a manual install walkthrough. This version is for
building pinned source releases into unofficial brozkeff `.deb` packages on an
Ubuntu 24.04 runner.

## Inputs

- `open-quantum-safe/liboqs` tag `0.15.0`
- `open-quantum-safe/oqs-provider` tag `0.11.0`
- Ubuntu 24.04 GitHub-hosted runner

Builds run only on tag pushes or manual `workflow_dispatch` runs. Tag pushes
publish releases automatically; manual runs publish workflow artifacts unless
`publish_release` is enabled.

## Install build dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  astyle \
  cmake \
  gcc \
  git \
  ninja-build \
  libssl-dev \
  python3-pytest \
  python3-pytest-xdist \
  unzip \
  xsltproc \
  doxygen \
  graphviz \
  python3-yaml \
  valgrind
```

## Build liboqs

```bash
git clone --branch 0.15.0 --depth 1 https://github.com/open-quantum-safe/liboqs.git
cmake -S liboqs -B liboqs/build -GNinja -DBUILD_SHARED_LIBS=ON
cmake --build liboqs/build

# Intentionally skipped for the first successful pipeline run.
# cmake --build liboqs/build --target run_tests

cmake --build liboqs/build --target gen_docs
cmake --build liboqs/build --target package
sudo apt-get install -y ./liboqs/build/liboqs-0.15.0-Linux.deb
sudo ldconfig
```

## Build oqs-provider

```bash
git clone --branch 0.11.0 --depth 1 https://github.com/open-quantum-safe/oqs-provider.git
cmake -S oqs-provider -B oqs-provider/_build
cmake --build oqs-provider/_build
ctest --test-dir oqs-provider/_build --parallel 2 --rerun-failed --output-on-failure
cmake --build oqs-provider/_build --target package
```

## Repack package versions

The workflow repacks the generated Debian packages so their internal
`Version:` fields include the repository build identity:

```text
+brozkeff.YYYYMMDD.g<repo-sha>
```

That makes the packages visibly unofficial even after installation with `dpkg`.

## Install and activate

```bash
sudo apt-get install -y ./dist/liboqs_*.deb ./dist/oqs-provider_*.deb
sudo scripts/enable-oqsprovider.sh --unattended
openssl list -providers
```

The activation script is shared by local users and CI. It backs up
`/etc/ssl/openssl.cnf`, patches the provider sections, and verifies that both
`default` and `oqsprovider` are active.
