#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"

SSHD_AUTH_OVERRIDE="/etc/ssh/sshd_config.d/99-provision-auth.conf"
mkdir -p /etc/ssh/sshd_config.d

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
systemctl restart ssh || systemctl restart sshd

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
