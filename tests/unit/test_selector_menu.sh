#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

SELECTOR="$ROOT_DIR/provision"

assert_file_exists "$SELECTOR" "Selector script must exist"

assert_contains "$SELECTOR" 'echo "1\) Tailscale Bootstrap"' "Menu option 1 must exist"
assert_contains "$SELECTOR" 'echo "2\) Admin User \+ SSH Setup"' "Menu option 2 must exist"
assert_contains "$SELECTOR" 'echo "3\) SSH Access Policy"' "Menu option 3 must exist"
assert_contains "$SELECTOR" 'echo "4\) Baseline OS"' "Menu option 4 must exist"
assert_contains "$SELECTOR" 'echo "5\) Verify Posture"' "Menu option 5 must exist"
assert_contains "$SELECTOR" 'echo "6\) Edit Config"' "Menu option 6 must exist"
assert_contains "$SELECTOR" 'echo "7\) Run Recommended Sequence"' "Menu option 7 must exist"
assert_contains "$SELECTOR" 'echo "8\) Show Status"' "Menu option 8 must exist"
assert_contains "$SELECTOR" 'echo "9\) Backup SSH/UFW/Provision Config"' "Menu option 9 must exist"
assert_contains "$SELECTOR" 'echo "10\) Reset Completion Markers"' "Menu option 10 must exist"
assert_contains "$SELECTOR" 'echo "11\) Print Effective Config"' "Menu option 11 must exist"
assert_contains "$SELECTOR" 'echo "12\) Rotate User SSH Key"' "Menu option 12 must exist"

assert_contains "$SELECTOR" '12\) run_sector "\$SECTOR_DIR/11-ssh-key-rotate.sh" ;;' "Menu option 12 must be wired"

pass "Selector menu options"

