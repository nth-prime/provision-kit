#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root

print_pubkey_help() {
  echo
  echo "Public SSH key help:"
  echo "  Linux/macOS:"
  echo "    ssh-keygen -t ed25519 -C \"your-label\""
  echo "    cat ~/.ssh/id_ed25519.pub"
  echo "  Windows PowerShell:"
  echo "    ssh-keygen -t ed25519 -C \"your-label\""
  echo "    Get-Content \$env:USERPROFILE\\.ssh\\id_ed25519.pub"
  echo "Paste the full line that starts with: ssh-ed25519 (or ssh-rsa/ssh-ecdsa)."
  echo
}

is_valid_pubkey() {
  local key="$1"
  [[ "$key" =~ ^ssh-(rsa|ed25519|ecdsa) ]] || return 1
  if command -v ssh-keygen >/dev/null 2>&1; then
    printf '%s\n' "$key" | ssh-keygen -l -f - >/dev/null 2>&1 || return 1
  fi
  return 0
}

read -rp "Username to rotate SSH key(s): " USER
if [[ -z "$USER" ]]; then
  echo "Username cannot be empty."
  exit 1
fi

if ! id "$USER" >/dev/null 2>&1; then
  echo "User does not exist: $USER"
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

BACKUP_DIR="/var/backups/provision-kit/authorized_keys"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/${USER}-$(date -u +%Y%m%dT%H%M%SZ).authorized_keys.bak"
cp -a "$AUTH_KEYS" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

echo
echo "Current keys for $USER:"
awk '
  BEGIN { n=0 }
  /^[[:space:]]*$/ { next }
  /^[[:space:]]*#/ { next }
  { n++; printf "%d) %s\n", n, $0 }
  END { if (n==0) print "(none)" }
' "$AUTH_KEYS"

echo
echo "Select action:"
echo "1) Replace all keys with one new key"
echo "2) Remove one existing key and optionally add a new key"
echo "3) Add a new key (keep existing keys)"
echo "q) Cancel"
read -rp "Choice: " choice

case "$choice" in
  1)
    print_pubkey_help
    read -rp "Paste new public SSH key: " NEWKEY
    if ! is_valid_pubkey "$NEWKEY"; then
      echo "Invalid public key format."
      exit 1
    fi
    printf '%s\n' "$NEWKEY" > "$AUTH_KEYS"
    chown "$USER:$USER" "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    echo "Replaced all keys for $USER."
    ;;
  2)
    KEY_COUNT="$(awk '/^[[:space:]]*($|#)/ { next } { n++ } END { print n+0 }' "$AUTH_KEYS")"
    if (( KEY_COUNT == 0 )); then
      echo "No keys to remove."
      exit 1
    fi
    read -rp "Enter key number to remove (1-$KEY_COUNT): " IDX
    if [[ ! "$IDX" =~ ^[0-9]+$ ]] || (( IDX < 1 || IDX > KEY_COUNT )); then
      echo "Invalid key selection."
      exit 1
    fi

    awk -v target="$IDX" '
      /^[[:space:]]*$/ { print; next }
      /^[[:space:]]*#/ { print; next }
      { n++; if (n != target) print }
    ' "$AUTH_KEYS" > "${AUTH_KEYS}.tmp"
    mv "${AUTH_KEYS}.tmp" "$AUTH_KEYS"
    chown "$USER:$USER" "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    echo "Removed key #$IDX for $USER."

    read -rp "Add replacement key now? (y/n): " ADDNEW
    if [[ "$ADDNEW" =~ ^[yY]$ ]]; then
      print_pubkey_help
      read -rp "Paste replacement public SSH key: " NEWKEY
      if ! is_valid_pubkey "$NEWKEY"; then
        echo "Invalid public key format."
        exit 1
      fi
      if ! grep -qxF "$NEWKEY" "$AUTH_KEYS"; then
        printf '%s\n' "$NEWKEY" >> "$AUTH_KEYS"
      fi
      chown "$USER:$USER" "$AUTH_KEYS"
      chmod 600 "$AUTH_KEYS"
      echo "Replacement key added."
    fi
    ;;
  3)
    print_pubkey_help
    read -rp "Paste new public SSH key: " NEWKEY
    if ! is_valid_pubkey "$NEWKEY"; then
      echo "Invalid public key format."
      exit 1
    fi
    if grep -qxF "$NEWKEY" "$AUTH_KEYS"; then
      echo "Key already present."
      exit 0
    fi
    printf '%s\n' "$NEWKEY" >> "$AUTH_KEYS"
    chown "$USER:$USER" "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    echo "Added key for $USER."
    ;;
  q|Q)
    echo "Canceled."
    exit 0
    ;;
  *)
    echo "Invalid selection."
    exit 1
    ;;
esac

mark_done 11-ssh-key-rotate.done
