#!/usr/bin/env bash
set -euo pipefail

PROVISION_BASE_DIR="${PROVISION_BASE_DIR:-/opt/provision-kit}"
source "$PROVISION_BASE_DIR/lib/lib.sh"
require_root

if ! dpkg -s unattended-upgrades >/dev/null 2>&1; then
  apt-get update
  apt-get install -y unattended-upgrades
fi

systemctl enable --now unattended-upgrades
echo "Ensured unattended-upgrades is enabled and active."
