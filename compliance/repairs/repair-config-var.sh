#!/usr/bin/env bash
set -euo pipefail

PROVISION_BASE_DIR="${PROVISION_BASE_DIR:-/opt/provision-kit}"
source "$PROVISION_BASE_DIR/lib/lib.sh"
require_root
require_config

VAR_NAME="${1:-}"
DEFAULT_VALUE="${2:-}"

if [[ -z "$VAR_NAME" ]]; then
  echo "repair-config-var: missing variable name."
  exit 1
fi

if [[ ! "$VAR_NAME" =~ ^[A-Z0-9_]+$ ]]; then
  echo "repair-config-var: invalid variable name '$VAR_NAME'."
  exit 1
fi

if [[ "$DEFAULT_VALUE" == "__EMPTY__" ]]; then
  DEFAULT_VALUE=""
fi

if grep -q "^${VAR_NAME}=" "$CONFIG"; then
  escaped="$(printf '%s' "$DEFAULT_VALUE" | sed 's/[&|]/\\&/g')"
  sed -i "s|^${VAR_NAME}=.*$|${VAR_NAME}=\"${escaped}\"|" "$CONFIG"
else
  printf '%s="%s"\n' "$VAR_NAME" "$DEFAULT_VALUE" >> "$CONFIG"
fi

echo "Set ${VAR_NAME} in $CONFIG."
