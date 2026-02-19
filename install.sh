#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/opt/provision-kit"
CONFIG_DIR="/etc/provision-kit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $(id -u) -ne 0 ]]; then
  echo "Run with sudo."
  exit 1
fi

echo "Installing Provision Kit..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# Copy repository contents except VCS metadata.
find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -a {} "$INSTALL_DIR/" \;

if [[ ! -f "$CONFIG_DIR/provision.conf" ]]; then
  install -m 600 "$INSTALL_DIR/config/provision.conf.example" "$CONFIG_DIR/provision.conf"
  echo "Created default config at $CONFIG_DIR/provision.conf"
fi

ln -sf "$INSTALL_DIR/provision" /usr/local/bin/provision-kit
chmod +x \
  "$INSTALL_DIR/provision" \
  "$INSTALL_DIR"/sectors/*.sh \
  "$INSTALL_DIR"/compliance/repairs/*.sh \
  "$INSTALL_DIR"/tests/tester \
  "$INSTALL_DIR"/tests/unit/*.sh \
  "$INSTALL_DIR"/compliance/tests/*.sh \
  /usr/local/bin/provision-kit

echo "Install complete."
echo "Run: provision-kit"
