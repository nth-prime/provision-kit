#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"
source /opt/provision-kit/sectors/compliance/checks.sh

echo "Compliance selector:"
echo "1) Standard compliance check"
echo "2) Verbose walk-through"
echo "3) Show raw system state only"
echo "q) Cancel"
read -rp "Select: " mode

case "$mode" in
  1)
    COMPLIANCE_VERBOSE=0
    run_compliance_checks
    mark_done 95-compliance-check.done
    ;;
  2)
    COMPLIANCE_VERBOSE=1
    run_compliance_checks
    mark_done 95-compliance-check.done
    ;;
  3)
    show_raw_state
    ;;
  q|Q)
    echo "Canceled."
    exit 0
    ;;
  *)
    echo "Invalid selection."
    exit 1
    ;;
esac
