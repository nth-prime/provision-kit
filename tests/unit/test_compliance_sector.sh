#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

COMPLIANCE_SECTOR="$ROOT_DIR/sectors/95-compliance-check.sh"
COMPLIANCE_MODULE="$ROOT_DIR/sectors/compliance/checks.sh"

assert_file_exists "$COMPLIANCE_SECTOR" "Compliance sector must exist"
assert_file_exists "$COMPLIANCE_MODULE" "Compliance module must exist"
assert_contains "$COMPLIANCE_SECTOR" 'require_config' "Compliance sector must require config"
assert_contains "$COMPLIANCE_SECTOR" 'Compliance selector:' "Compliance sector must present selector menu"
assert_contains "$COMPLIANCE_SECTOR" 'run_compliance_checks' "Compliance sector must invoke compliance module checks"
assert_contains "$COMPLIANCE_SECTOR" 'mark_done 95-compliance-check.done' "Compliance sector must write completion marker"
assert_contains "$COMPLIANCE_MODULE" 'ENFORCE_TAILSCALE_ACCESS must be 1' "Compliance module must enforce tailscale access"
assert_contains "$COMPLIANCE_MODULE" 'mkdir -p /run/sshd' "Compliance module must prepare sshd runtime dir before checks"
assert_contains "$COMPLIANCE_MODULE" 'DEBUG:' "Compliance module should include verbose debug output"
assert_contains "$COMPLIANCE_MODULE" 'permitrootlogin no' "Compliance module must verify root login disabled"
assert_contains "$COMPLIANCE_MODULE" 'passwordauthentication no' "Compliance module must verify password auth disabled"

pass "Compliance sector"
