#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"

SSHD_AUTH_OVERRIDE="/etc/ssh/sshd_config.d/99-provision-auth.conf"
mkdir -p /etc/ssh/sshd_config.d

restart_ssh_daemon() {
  local restarted=0

  if systemctl list-unit-files | grep -q '^ssh\.service'; then
    if systemctl restart ssh; then
      restarted=1
    else
      echo "Failed to restart ssh.service. Recent logs:"
      journalctl -u ssh -n 30 --no-pager || true
    fi
  fi

  if [[ "$restarted" == "0" ]] && systemctl list-unit-files | grep -q '^sshd\.service'; then
    if systemctl restart sshd; then
      restarted=1
    else
      echo "Failed to restart sshd.service. Recent logs:"
      journalctl -u sshd -n 30 --no-pager || true
    fi
  fi

  if [[ "$restarted" == "0" ]]; then
    echo "Unable to restart SSH daemon: neither ssh.service nor sshd.service restarted successfully."
    return 1
  fi
}

echo "Repairing SSH auth override..."

cat > "$SSHD_AUTH_OVERRIDE" <<EOF
PermitRootLogin no
PasswordAuthentication no
EOF

echo "Auth override written: $SSHD_AUTH_OVERRIDE"
echo "Current PasswordAuthentication declarations:"
grep -Rni '^[[:space:]]*PasswordAuthentication' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true

mkdir -p /run/sshd
sshd -t
restart_ssh_daemon

EFFECTIVE="$(sshd -T 2>/dev/null || true)"
echo "Effective sshd auth settings:"
echo "$EFFECTIVE" | grep -E 'permitrootlogin|passwordauthentication' || true

if echo "$EFFECTIVE" | grep -Eq '^passwordauthentication no$'; then
  echo "SSH auth repair succeeded."
else
  echo "SSH auth repair did not take effect. Inspect config chain."
  exit 1
fi

mark_done 16-ssh-auth-repair.done
