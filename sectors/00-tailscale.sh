#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root

if ! command -v tailscale >/dev/null 2>&1; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

if tailscale ip -4 >/dev/null 2>&1; then
  echo "Tailscale already connected."
else
  read -rsp "Enter Tailscale auth key: " KEY
  echo
  tailscale up --authkey "$KEY" --ssh
fi

echo "Tailscale IPv4:"
tailscale ip -4 || true

mark_done 00-tailscale.done
