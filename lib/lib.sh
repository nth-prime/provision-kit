#!/usr/bin/env bash
set -euo pipefail

CONFIG="/etc/provision-kit/provision.conf"

require_root() {
  if [[ $(id -u) -ne 0 ]]; then
    echo "Run with sudo."
    exit 1
  fi
}

require_config() {
  if [[ ! -f "$CONFIG" ]]; then
    echo "Missing config: $CONFIG"
    exit 1
  fi
}

confirm() {
  read -rp "$1 (y/n): " yn
  [[ "$yn" =~ ^[yY]$ ]]
}

mark_done() {
  mkdir -p /var/lib/provision-kit
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "/var/lib/provision-kit/$1"
}

is_done() {
  [[ -f "/var/lib/provision-kit/$1" ]]
}
