#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

COMPLIANCE_SECTOR="$ROOT_DIR/sectors/95-compliance-check.sh"
COMPLIANCE_ENGINE="$ROOT_DIR/compliance/lib/engine.sh"
COMPLIANCE_CHECKS="$ROOT_DIR/compliance/lib/checks.sh"
COMPLIANCE_TEST="$ROOT_DIR/compliance/tests/test_check_repair_mapping.sh"

assert_file_exists "$COMPLIANCE_SECTOR" "Compliance sector must exist"
assert_file_exists "$COMPLIANCE_ENGINE" "Compliance engine must exist"
assert_file_exists "$COMPLIANCE_CHECKS" "Compliance checks module must exist"
assert_file_exists "$COMPLIANCE_TEST" "Compliance tests must exist"
assert_contains "$COMPLIANCE_SECTOR" 'require_config' "Compliance sector must require config"
assert_not_contains "$COMPLIANCE_SECTOR" 'Compliance selector:' "Compliance sector selector menu must be removed"
assert_not_contains "$COMPLIANCE_SECTOR" 'read -rp "Select: "' "Compliance sector must not prompt for nested selector choices"
assert_contains "$COMPLIANCE_SECTOR" 'run_compliance_pipeline' "Compliance sector must invoke compliance pipeline"
assert_contains "$COMPLIANCE_SECTOR" 'mark_done 95-compliance-check.done' "Compliance sector must write completion marker"
assert_contains "$COMPLIANCE_ENGINE" 'Action for \[' "Compliance engine must prompt on failures"
assert_contains "$COMPLIANCE_ENGINE" '\[R\]epair/\[I\]gnore/\[A\]bort' "Compliance engine must offer repair or ignore choices"
assert_contains "$COMPLIANCE_ENGINE" 'R\|REPAIR' "Compliance engine must accept full-word repair action"
assert_contains "$COMPLIANCE_ENGINE" 'I\|IGNORE' "Compliance engine must accept full-word ignore action"
assert_contains "$COMPLIANCE_ENGINE" 'A\|ABORT' "Compliance engine must accept full-word abort action"
assert_contains "$COMPLIANCE_ENGINE" 'Compliance completed with ignored issues\.' "Compliance engine must fail when issues are ignored"
assert_contains "$COMPLIANCE_ENGINE" 'Compliance aborted by user' "Compliance engine must support user abort path"
assert_contains "$COMPLIANCE_ENGINE" 'Input stream closed\. Aborting compliance\.' "Compliance engine must abort cleanly on non-interactive input closure"
assert_contains "$COMPLIANCE_CHECKS" 'list_compliance_checks' "Compliance checks module must register checks"
assert_contains "$COMPLIANCE_CHECKS" 'repair-config-var.sh' "Compliance checks must map to repair strategies"
assert_contains "$COMPLIANCE_CHECKS" 'repair-ssh-auth.sh' "Compliance checks must include SSH auth repair"
assert_contains "$COMPLIANCE_CHECKS" 'repair-unattended-upgrades.sh' "Compliance checks must include unattended-upgrades repair"

pass "Compliance sector"
