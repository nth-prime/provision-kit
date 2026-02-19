#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"

print_pubkey_help() {
  echo
  echo "Public SSH key help:"
  echo "  Linux/macOS:"
  echo "    ssh-keygen -C \"your-label\""
  echo "    cat ~/.ssh/id_ed25519.pub"
  echo "  Windows PowerShell:"
  echo "    ssh-keygen -C \"your-label\""
  echo '    Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub'
  echo "Paste the full line that starts with: ssh-ed25519 (or ssh-rsa/ssh-ecdsa)."
  echo
}

read -rp "Admin username: " USER
if [[ -z "$USER" ]]; then
  echo "Username cannot be empty."
  exit 1
fi

if ! id "$USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$USER"
fi
usermod -aG sudo "$USER"

if [[ -z "${ADMIN_SUDO_PASSWORD:-}" ]]; then
  echo "ADMIN_SUDO_PASSWORD is not set in $CONFIG"
  exit 1
fi
echo "$USER:$ADMIN_SUDO_PASSWORD" | chpasswd
echo "Set local sudo password for $USER from config policy."

print_pubkey_help
read -rp "Paste public SSH key: " PUBKEY
if [[ ! "$PUBKEY" =~ ^ssh-(rsa|ed25519|ecdsa) ]]; then
  echo "Key format does not look like an OpenSSH public key."
  exit 1
fi

USER_HOME="$(getent passwd "$USER" | cut -d: -f6)"
if [[ -z "$USER_HOME" || "$USER_HOME" == "/" ]]; then
  echo "Unable to determine a safe home directory for $USER."
  exit 1
fi

SSH_DIR="$USER_HOME/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

install -d -m 700 -o "$USER" -g "$USER" "$SSH_DIR"
touch "$AUTH_KEYS"
chown "$USER:$USER" "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"

if ! grep -qxF "$PUBKEY" "$AUTH_KEYS"; then
  echo "$PUBKEY" >> "$AUTH_KEYS"
  echo "Added key for $USER."
else
  echo "Key already present for $USER."
fi

if id "${DEFAULT_USER_NAME:-ubuntu}" >/dev/null 2>&1; then
  echo "WARNING: default cloud user '${DEFAULT_USER_NAME:-ubuntu}' exists; review and disable if not needed."
fi

mark_done 10-user-ssh.done
