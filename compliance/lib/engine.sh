#!/usr/bin/env bash
set -euo pipefail

PROVISION_BASE_DIR="${PROVISION_BASE_DIR:-/opt/provision-kit}"

source "$PROVISION_BASE_DIR/compliance/lib/checks.sh"

COMPLIANCE_TOTAL=0
COMPLIANCE_PASSED=0
COMPLIANCE_REPAIRED=0
COMPLIANCE_IGNORED=0

print_detail() {
  if [[ -n "${COMPLIANCE_LAST_DETAIL:-}" ]]; then
    echo "DETAIL: $COMPLIANCE_LAST_DETAIL"
  fi
}

run_repair() {
  local repair_script="$1"
  local repair_args="${2:-}"

  if [[ ! -f "$repair_script" ]]; then
    echo "Repair strategy missing: $repair_script"
    return 1
  fi

  echo "Running repair: $repair_script ${repair_args}"
  if [[ -n "$repair_args" ]]; then
    # shellcheck disable=SC2086
    bash "$repair_script" $repair_args
  else
    bash "$repair_script"
  fi
}

handle_failure() {
  local check_id="$1"
  local description="$2"
  local check_fn="$3"
  local repair_script="$4"
  local repair_args="${5:-}"
  local action

  while true; do
    read -rp "Action for [$check_id] [R]epair/[I]gnore/[A]bort (default: R): " action
    action="${action:-R}"
    case "${action^^}" in
      R)
        if run_repair "$repair_script" "$repair_args"; then
          if "$check_fn"; then
            echo "PASS (after repair): $description"
            print_detail
            COMPLIANCE_REPAIRED=$((COMPLIANCE_REPAIRED + 1))
            COMPLIANCE_PASSED=$((COMPLIANCE_PASSED + 1))
            return 0
          fi
          echo "Repair ran but check still fails."
          print_detail
        else
          echo "Repair execution failed."
        fi
        ;;
      I)
        echo "IGNORED: $description"
        COMPLIANCE_IGNORED=$((COMPLIANCE_IGNORED + 1))
        return 0
        ;;
      A)
        echo "Compliance aborted by user on check [$check_id]."
        return 1
        ;;
      *)
        echo "Invalid input. Use R, I, or A."
        ;;
    esac
  done
}

run_compliance_pipeline() {
  COMPLIANCE_TOTAL=0
  COMPLIANCE_PASSED=0
  COMPLIANCE_REPAIRED=0
  COMPLIANCE_IGNORED=0

  local line check_id description check_fn repair_script repair_args
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    IFS='|' read -r check_id description check_fn repair_script repair_args <<< "$line"

    COMPLIANCE_TOTAL=$((COMPLIANCE_TOTAL + 1))
    echo
    echo "CHECK [$check_id]: $description"

    if "$check_fn"; then
      echo "PASS: $description"
      print_detail
      COMPLIANCE_PASSED=$((COMPLIANCE_PASSED + 1))
      continue
    fi

    echo "FAIL: $description"
    print_detail
    if ! handle_failure "$check_id" "$description" "$check_fn" "$repair_script" "$repair_args"; then
      return 1
    fi
  done < <(list_compliance_checks)

  echo
  echo "Compliance summary: total=$COMPLIANCE_TOTAL passed=$COMPLIANCE_PASSED repaired=$COMPLIANCE_REPAIRED ignored=$COMPLIANCE_IGNORED"
  if (( COMPLIANCE_IGNORED > 0 )); then
    echo "Compliance completed with ignored issues."
    return 1
  fi

  echo "Compliance check passed with no ignored issues."
  return 0
}
