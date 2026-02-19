#!/usr/bin/env bash
set -euo pipefail

PROVISION_BASE_DIR="${PROVISION_BASE_DIR:-/opt/provision-kit}"
source "$PROVISION_BASE_DIR/lib/lib.sh"
require_root
require_config

mkdir -p /run/sshd
echo "Ensured /run/sshd exists."

if ! sshd -T >/dev/null 2>&1; then
  echo "sshd -T still failing; reapplying SSH access policy."
  bash "$PROVISION_BASE_DIR/sectors/15-ssh-access.sh"
fi
