#!/usr/bin/env bash
set -euo pipefail

PROVISION_BASE_DIR="${PROVISION_BASE_DIR:-/opt/provision-kit}"
source "$PROVISION_BASE_DIR/lib/lib.sh"
require_root
require_config

bash "$PROVISION_BASE_DIR/sectors/16-ssh-auth-repair.sh"
