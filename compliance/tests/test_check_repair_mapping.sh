#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

PROVISION_BASE_DIR="$ROOT_DIR"
source "$ROOT_DIR/compliance/lib/checks.sh"

count=0
seen_ids=""
while IFS='|' read -r check_id description check_fn repair_script repair_args; do
  [[ -n "$check_id" ]] || continue
  count=$((count + 1))
  if [[ ! "$check_id" =~ ^[a-z0-9_]+$ ]]; then
    fail "Check id '$check_id' must use lowercase snake_case"
  fi
  if echo "$seen_ids" | tr ' ' '\n' | grep -qx "$check_id"; then
    fail "Duplicate check id: $check_id"
  fi
  seen_ids="$seen_ids $check_id"
  assert_not_empty "$description" "Check '$check_id' must have description"
  assert_not_empty "$check_fn" "Check '$check_id' must have check function"
  assert_not_empty "$repair_script" "Check '$check_id' must have repair strategy"
  assert_file_exists "$repair_script" "Repair script for '$check_id' must exist"
  assert_contains "$repair_script" '/usr/bin/env bash' "Repair script for '$check_id' must be a bash script"
  if [[ "$repair_script" != "$ROOT_DIR"/compliance/repairs/* ]]; then
    fail "Repair script for '$check_id' must live under compliance/repairs"
  fi
  if ! declare -F "$check_fn" >/dev/null 2>&1; then
    fail "Check function '$check_fn' missing for check '$check_id'"
  fi
done < <(list_compliance_checks)

if (( count == 0 )); then
  fail "No compliance checks were registered"
fi

pass "Compliance check->repair mapping"
