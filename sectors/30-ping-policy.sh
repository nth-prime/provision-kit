#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"

CURRENT_V4="$(sysctl -n net.ipv4.icmp_echo_ignore_all 2>/dev/null || echo 0)"
CURRENT_V6="$(sysctl -n net.ipv6.icmp.echo_ignore_all 2>/dev/null || echo 0)"

if [[ "$CURRENT_V4" == "0" && "$CURRENT_V6" == "0" ]]; then
  echo "Current ping policy: ENABLED"
else
  echo "Current ping policy: DISABLED"
fi

DEFAULT_ALLOW_PING="${ALLOW_PING:-0}"
if [[ ! "$DEFAULT_ALLOW_PING" =~ ^[01]$ ]]; then
  echo "Invalid ALLOW_PING value in config. Expected 0 or 1, got: $DEFAULT_ALLOW_PING"
  exit 1
fi

echo "Select ping policy:"
echo "1) Enable ping replies"
echo "2) Disable ping replies"
echo "3) Apply config default (ALLOW_PING=$DEFAULT_ALLOW_PING)"
read -rp "Choice: " choice

case "$choice" in
  1) TARGET_ALLOW_PING=1 ;;
  2) TARGET_ALLOW_PING=0 ;;
  3) TARGET_ALLOW_PING="$DEFAULT_ALLOW_PING" ;;
  *) echo "Invalid selection."; exit 1 ;;
esac

if [[ "$TARGET_ALLOW_PING" == "1" ]]; then
  V4_VALUE=0
  V6_VALUE=0
  echo "Applying policy: ENABLE ping replies"
else
  V4_VALUE=1
  V6_VALUE=1
  echo "Applying policy: DISABLE ping replies"
fi

cat > /etc/sysctl.d/99-provision-ping.conf <<EOF
# Managed by Provision Kit (30-ping-policy.sh)
net.ipv4.icmp_echo_ignore_all=$V4_VALUE
net.ipv6.icmp.echo_ignore_all=$V6_VALUE
EOF

sysctl --system >/dev/null

echo "Ping policy updated."
mark_done 30-ping-policy.done
