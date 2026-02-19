#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root

if [[ -f "$CONFIG" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG"
fi

REPO_URL="${PROVISION_KIT_REPO_URL:-https://github.com/nth-prime/provision-kit}"
REPO_BRANCH="${PROVISION_KIT_BRANCH:-main}"
TARBALL_URL="${REPO_URL%/}/archive/refs/heads/${REPO_BRANCH}.tar.gz"

echo "Update source: $TARBALL_URL"
read -rp "Download and reinstall Provision Kit from this source now? (y/n): " yn
[[ "$yn" =~ ^[yY]$ ]] || exit 0

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_PATH="$TMP_DIR/provision-kit.tar.gz"
curl -fsSL "$TARBALL_URL" -o "$ARCHIVE_PATH"
tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

SRC_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$SRC_DIR" || ! -f "$SRC_DIR/install.sh" ]]; then
  echo "Update failed: extracted content did not contain install.sh"
  exit 1
fi

(cd "$SRC_DIR" && bash "./install.sh")
if [[ -f /opt/provision-kit/VERSION ]]; then
  UPDATED_VERSION="$(tr -d '[:space:]' < /opt/provision-kit/VERSION)"
  echo "Provision Kit update complete. Installed version: $UPDATED_VERSION"
else
  echo "Provision Kit update complete."
fi

mark_done 05-update-kit.done
