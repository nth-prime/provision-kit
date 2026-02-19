#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root

echo "Hostname: $(hostname)"
echo "Tailscale:"
tailscale status || true

echo "Listening ports:"
ss -tulpn

echo "SSHD config (effective):"
sshd -T | grep -E 'permitrootlogin|passwordauthentication|kbdinteractiveauthentication|allowtcpforwarding|allowagentforwarding|maxauthtries|maxsessions'

echo "UFW:"
ufw status verbose

echo "Unattended upgrades:"
systemctl is-enabled unattended-upgrades
systemctl is-active unattended-upgrades

echo "Verification complete."
