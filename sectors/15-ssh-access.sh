#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"

if [[ "${ENFORCE_TAILSCALE_ACCESS:-1}" != "1" ]]; then
  echo "Refusing to continue: ENFORCE_TAILSCALE_ACCESS must be 1"
  exit 1
fi

if [[ ! "${SSH_PORT:-}" =~ ^[0-9]+$ ]] || (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
  echo "Invalid SSH_PORT: ${SSH_PORT:-unset}"
  exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ufw
fi

if ! command -v sshd >/dev/null 2>&1; then
  apt-get update
  apt-get install -y openssh-server
fi

SSHD_DROPIN="/etc/ssh/sshd_config.d/95-provision.conf"
SSHD_AUTH_OVERRIDE="/etc/ssh/sshd_config.d/99-provision-auth.conf"
mkdir -p /etc/ssh/sshd_config.d

cat > "$SSHD_DROPIN" <<EOF
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
AllowTcpForwarding no
AllowAgentForwarding no
MaxAuthTries 3
MaxSessions 2
EOF

# Final auth override to ensure late-loaded config cannot re-enable password SSH/root login.
cat > "$SSHD_AUTH_OVERRIDE" <<EOF
PermitRootLogin no
PasswordAuthentication no
EOF

sshd -t
systemctl restart ssh || systemctl restart sshd

if [[ "${UFW_FORCE_RESET:-0}" == "1" ]]; then
  ufw --force reset
fi
ufw default deny incoming
ufw default allow outgoing

ufw allow in on tailscale0 to any port "$SSH_PORT" proto tcp

if [[ "${SSH_ALLOW_PUBLIC_WHITELIST:-0}" == "1" ]]; then
  for cidr in ${SSH_WHITELIST_IPV4:-}; do
    ufw allow from "$cidr" to any port "$SSH_PORT" proto tcp
  done
  for cidr in ${SSH_WHITELIST_IPV6:-}; do
    ufw allow from "$cidr" to any port "$SSH_PORT" proto tcp
  done
fi

ufw --force enable

mark_done 15-ssh-access.done
