#!/usr/bin/env bash
set -euo pipefail

CONFIG=/etc/ssl/openssl.cnf
UNATTENDED=0

usage() {
  cat <<'EOF'
Usage: sudo scripts/enable-oqsprovider.sh [--unattended] [--config PATH]

Enables oqsprovider in an OpenSSL configuration file and verifies:
  openssl list -providers

Interactive runs warn and ask before modifying openssl.cnf.
CI/CD runs must pass --unattended, otherwise noninteractive execution fails.

Revert:
  sudo cp <printed-backup-path> /etc/ssl/openssl.cnf
  openssl list -providers
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --unattended)
      UNATTENDED=1
      shift
      ;;
    --config)
      CONFIG=${2:?--config requires a path}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$UNATTENDED" -eq 0 ]; then
  if [ ! -t 0 ]; then
    echo "Refusing noninteractive run without --unattended." >&2
    exit 2
  fi

  cat >&2 <<EOF
WARNING: this script modifies ${CONFIG}.

Risk: a broken OpenSSL configuration can break OpenSSL-based tools on this
machine, including package downloads, TLS clients, and services using OpenSSL.

The script creates a timestamped backup before writing. To revert, restore that
backup:

  sudo cp <backup-path> ${CONFIG}
  openssl list -providers

EOF
  read -r -p "Type 'enable oqsprovider' to continue: " answer
  if [ "$answer" != "enable oqsprovider" ]; then
    echo "Aborted." >&2
    exit 1
  fi
fi

if [ ! -f "$CONFIG" ]; then
  echo "OpenSSL config not found: $CONFIG" >&2
  exit 1
fi

BACKUP="${CONFIG}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
TMP_CONFIG="$(mktemp)"
trap 'rm -f "$TMP_CONFIG"' EXIT

python3 - "$CONFIG" "$TMP_CONFIG" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

config = Path(sys.argv[1])
tmp_config = Path(sys.argv[2])

text = config.read_text()
lines = text.splitlines(keepends=True)


def first_section_index() -> int:
    header = re.compile(r"^\s*\[[^\]]+\]\s*(?:[#;].*)?$")
    for idx, line in enumerate(lines):
        if header.match(line):
            return idx
    return len(lines)


def ensure_global_key(key: str, value: str) -> None:
    end = first_section_index()
    key_re = re.compile(rf"^\s*[#;]?\s*{re.escape(key)}\s*=")

    for idx in range(end):
        if key_re.match(lines[idx]):
            lines[idx] = f"{key} = {value}\n"
            return

    lines.insert(end, f"{key} = {value}\n")


def section_bounds(name: str) -> tuple[int, int]:
    header = re.compile(rf"^\s*\[{re.escape(name)}\]\s*(?:[#;].*)?$")
    any_header = re.compile(r"^\s*\[[^\]]+\]\s*(?:[#;].*)?$")

    start = None
    for idx, line in enumerate(lines):
        if header.match(line):
            start = idx
            break

    if start is None:
        if lines and not lines[-1].endswith("\n"):
            lines[-1] += "\n"
        lines.extend([f"\n[{name}]\n"])
        return len(lines) - 1, len(lines)

    end = len(lines)
    for idx in range(start + 1, len(lines)):
        if any_header.match(lines[idx]):
            end = idx
            break
    return start, end


def ensure_key(section: str, key: str, value: str) -> None:
    start, end = section_bounds(section)
    key_re = re.compile(rf"^\s*[#;]?\s*{re.escape(key)}\s*=")

    for idx in range(start + 1, end):
        if key_re.match(lines[idx]):
            lines[idx] = f"{key} = {value}\n"
            return

    insert_at = end
    lines.insert(insert_at, f"{key} = {value}\n")


ensure_global_key("openssl_conf", "openssl_init")
ensure_key("openssl_init", "providers", "provider_sect")
ensure_key("provider_sect", "default", "default_sect")
ensure_key("provider_sect", "oqsprovider", "oqsprovider_sect")
ensure_key("default_sect", "activate", "1")
ensure_key("oqsprovider_sect", "activate", "1")

tmp_config.write_text("".join(lines))
PY

if cmp -s "$CONFIG" "$TMP_CONFIG"; then
  echo "No change needed: $CONFIG"
else
  validation_output="$(OPENSSL_CONF="$TMP_CONFIG" openssl list -providers 2>&1)" || {
    printf '%s\n' "$validation_output" >&2
    echo "Patched config failed OpenSSL validation; not modifying $CONFIG." >&2
    exit 1
  }
  if ! printf '%s\n' "$validation_output" | grep -Eq '^[[:space:]]+default$' ||
     ! printf '%s\n' "$validation_output" | grep -Eq '^[[:space:]]+oqsprovider$'; then
    printf '%s\n' "$validation_output" >&2
    echo "Patched config did not activate default and oqsprovider; not modifying $CONFIG." >&2
    exit 1
  fi
  cp --preserve=mode,ownership,timestamps "$CONFIG" "$BACKUP"
  cat "$TMP_CONFIG" > "$CONFIG"
  echo "Backup written: $BACKUP"
  echo "Updated: $CONFIG"
fi

providers="$(openssl list -providers)"
printf '%s\n' "$providers"

printf '%s\n' "$providers" | grep -Eq '^[[:space:]]+default$'
printf '%s\n' "$providers" | grep -Eq '^[[:space:]]+oqsprovider$'

echo "OpenSSL default and oqsprovider providers are active."
