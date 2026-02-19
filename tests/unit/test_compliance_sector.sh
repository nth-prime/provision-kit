#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

COMPLIANCE_SECTOR="$ROOT_DIR/sectors/95-compliance-check.sh"

assert_file_exists "$COMPLIANCE_SECTOR" "Compliance sector must exist"
assert_contains "$COMPLIANCE_SECTOR" 'require_config' "Compliance sector must require config"
assert_contains "$COMPLIANCE_SECTOR" 'ENFORCE_TAILSCALE_ACCESS must be 1' "Compliance sector must enforce tailscale access"
assert_contains "$COMPLIANCE_SECTOR" 'mkdir -p /run/sshd' "Compliance sector must prepare sshd runtime dir before checks"
assert_contains "$COMPLIANCE_SECTOR" 'DEBUG:' "Compliance sector should include verbose debug output"
assert_contains "$COMPLIANCE_SECTOR" 'permitrootlogin no' "Compliance sector must verify root login disabled"
assert_contains "$COMPLIANCE_SECTOR" 'passwordauthentication no' "Compliance sector must verify password auth disabled"
assert_contains "$COMPLIANCE_SECTOR" 'mark_done 95-compliance-check.done' "Compliance sector must write completion marker"

pass "Compliance sector"
