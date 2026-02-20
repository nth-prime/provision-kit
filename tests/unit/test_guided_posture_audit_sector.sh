#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

SECTOR="$ROOT_DIR/sectors/91-guided-posture-audit.sh"

assert_file_exists "$SECTOR" "Guided posture audit sector must exist"
assert_contains "$SECTOR" 'Guided Posture Audit' "Guided posture audit sector must print a heading"
assert_contains "$SECTOR" 'Run this step now\? \(Y/n/q\): ' "Guided posture audit sector must prompt per-step confirmation"
assert_contains "$SECTOR" 'Step 1: Install Paths and Version' "Guided posture audit sector must include install path verification"
assert_contains "$SECTOR" 'Step 3: SSH Daemon Hardening' "Guided posture audit sector must include SSH hardening verification"
assert_contains "$SECTOR" 'Step 4: Firewall Rules' "Guided posture audit sector must include firewall verification"
assert_contains "$SECTOR" 'Step 8: User and Sudo Posture' "Guided posture audit sector must include sudo posture verification"
assert_contains "$SECTOR" 'mark_done 91-guided-posture-audit.done' "Guided posture audit sector must write completion marker"

pass "Guided posture audit sector"
