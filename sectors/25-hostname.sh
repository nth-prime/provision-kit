#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root

CURRENT_HOSTNAME="$(hostnamectl --static 2>/dev/null || hostname)"
echo "Current hostname: $CURRENT_HOSTNAME"
read -rp "New hostname: " NEW_HOSTNAME

if [[ -z "$NEW_HOSTNAME" ]]; then
  echo "Hostname cannot be empty."
  exit 1
fi

# RFC 1123-ish validation: labels with alnum + hyphen, no leading/trailing hyphen.
if [[ ! "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
  echo "Invalid hostname. Use 1-63 chars: letters, numbers, hyphens."
  exit 1
fi

if [[ "$NEW_HOSTNAME" == "$CURRENT_HOSTNAME" ]]; then
  echo "Hostname already set to $NEW_HOSTNAME."
  exit 0
fi

hostnamectl set-hostname "$NEW_HOSTNAME"
echo "Hostname updated to: $NEW_HOSTNAME"

mark_done 25-hostname.done
