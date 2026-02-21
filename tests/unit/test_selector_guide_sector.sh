#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

SECTOR="$ROOT_DIR/sectors/92-selector-guide.sh"

assert_file_exists "$SECTOR" "Selector guide sector must exist"
assert_contains "$SECTOR" 'Selector Guide \(What \+ Why\)' "Selector guide sector must print heading"
assert_contains "$SECTOR" '1\) Edit Config' "Selector guide sector must document option 1"
assert_contains "$SECTOR" '15\) Enforce Compliance Check' "Selector guide sector must document compliance option"
assert_contains "$SECTOR" '20\) Guided Posture Audit \(Manual\)' "Selector guide sector must document guided audit option"
assert_contains "$SECTOR" '21\) Selector Guide' "Selector guide sector must document itself"
assert_contains "$SECTOR" 'mark_done 92-selector-guide.done' "Selector guide sector must write completion marker"

pass "Selector guide sector"
