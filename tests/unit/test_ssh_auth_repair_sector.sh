#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

REPAIR_SECTOR="$ROOT_DIR/sectors/16-ssh-auth-repair.sh"

assert_file_exists "$REPAIR_SECTOR" "SSH auth repair sector must exist"
assert_contains "$REPAIR_SECTOR" '01-provision-auth.conf' "Repair sector must write early auth override file"
assert_contains "$REPAIR_SECTOR" 'PasswordAuthentication no' "Repair sector must enforce password auth disabled"
assert_contains "$REPAIR_SECTOR" 'PermitRootLogin no' "Repair sector must enforce root login disabled"
assert_contains "$REPAIR_SECTOR" 'sshd -t' "Repair sector must validate sshd config"
assert_contains "$REPAIR_SECTOR" 'systemctl restart ssh' "Repair sector must restart SSH service"
assert_contains "$REPAIR_SECTOR" 'mark_done 16-ssh-auth-repair.done' "Repair sector must write completion marker"

pass "SSH auth repair sector"
