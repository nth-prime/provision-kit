#!/usr/bin/env bash
set -euo pipefail

PROVISION_BASE_DIR="${PROVISION_BASE_DIR:-/opt/provision-kit}"
source "$PROVISION_BASE_DIR/lib/lib.sh"
require_root
require_config
source "$CONFIG"

if [[ "${ALLOW_CLOUD_INIT_ROOT_NOPASSWD:-1}" == "1" ]]; then
  echo "Strict sudoers policy is disabled in config (ALLOW_CLOUD_INIT_ROOT_NOPASSWD=1)."
  echo "Set ALLOW_CLOUD_INIT_ROOT_NOPASSWD=0 to enforce this repair."
  exit 1
fi

if [[ -f /etc/sudoers.d/90-cloud-init-users ]]; then
  cp -a /etc/sudoers.d/90-cloud-init-users "/etc/sudoers.d/90-cloud-init-users.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  sed -i 's/NOPASSWD:[[:space:]]*ALL/ALL/g' /etc/sudoers.d/90-cloud-init-users
  chmod 440 /etc/sudoers.d/90-cloud-init-users
  echo "Updated /etc/sudoers.d/90-cloud-init-users to remove NOPASSWD escalation."
fi

if ! visudo -cf /etc/sudoers >/dev/null; then
  echo "visudo validation failed after sudoers repair."
  exit 1
fi

remaining="$(grep -RniE '^[[:space:]]*[^#].*NOPASSWD' /etc/sudoers /etc/sudoers.d 2>/dev/null || true)"
if [[ -n "$remaining" ]]; then
  echo "NOPASSWD entries remain and require manual review:"
  echo "$remaining"
  exit 1
fi

echo "Sudoers NOPASSWD repair succeeded."
