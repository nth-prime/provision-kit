#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

SELECTOR="$ROOT_DIR/provision"

assert_file_exists "$SELECTOR" "Selector script must exist"

assert_contains "$SELECTOR" 'echo "1\) Edit Config"' "Menu option 1 must exist"
assert_contains "$SELECTOR" 'echo "2\) Run Recommended Sequence \(optional\)"' "Menu option 2 must exist"
assert_contains "$SELECTOR" 'echo "3\) Tailscale Bootstrap"' "Menu option 3 must exist"
assert_contains "$SELECTOR" 'echo "4\) Admin User \+ SSH Setup"' "Menu option 4 must exist"
assert_contains "$SELECTOR" 'echo "5\) SSH Access Policy"' "Menu option 5 must exist"
assert_contains "$SELECTOR" 'echo "6\) Baseline OS"' "Menu option 6 must exist"
assert_contains "$SELECTOR" 'echo "7\) Verify Posture"' "Menu option 7 must exist"
assert_contains "$SELECTOR" 'echo "8\) Show Status"' "Menu option 8 must exist"
assert_contains "$SELECTOR" 'echo "9\) Backup SSH/UFW/Provision Config"' "Menu option 9 must exist"
assert_contains "$SELECTOR" 'echo "10\) Reset Completion Markers"' "Menu option 10 must exist"
assert_contains "$SELECTOR" 'echo "11\) Print Effective Config"' "Menu option 11 must exist"
assert_contains "$SELECTOR" 'echo "12\) Change Server Hostname"' "Menu option 12 must exist"
assert_contains "$SELECTOR" 'echo "13\) Rotate User SSH Key"' "Menu option 13 must exist"
assert_contains "$SELECTOR" 'echo "14\) Run Unit Tests"' "Menu option 14 must exist"
assert_contains "$SELECTOR" 'echo "15\) Enforce Compliance Check"' "Menu option 15 must exist"
assert_contains "$SELECTOR" 'echo "16\) Restart Machine Now"' "Menu option 16 must exist"
assert_contains "$SELECTOR" 'echo "17\) Update Provision Kit from GitHub"' "Menu option 17 must exist"
assert_contains "$SELECTOR" 'echo "18\) Toggle Ping Policy"' "Menu option 18 must exist"

assert_contains "$SELECTOR" '1\) edit_config ;;' "Menu option 1 must be wired"
assert_contains "$SELECTOR" '2\) run_recommended_sequence ;;' "Menu option 2 must be wired"
assert_contains "$SELECTOR" '3\) run_sector "\$SECTOR_DIR/00-tailscale.sh" ;;' "Menu option 3 must be wired"
assert_contains "$SELECTOR" '4\) run_sector "\$SECTOR_DIR/10-user-ssh.sh" ;;' "Menu option 4 must be wired"
assert_contains "$SELECTOR" '5\) run_sector "\$SECTOR_DIR/15-ssh-access.sh" ;;' "Menu option 5 must be wired"
assert_contains "$SELECTOR" '6\) run_sector "\$SECTOR_DIR/20-baseline-os.sh" ;;' "Menu option 6 must be wired"
assert_contains "$SELECTOR" '7\) run_sector "\$SECTOR_DIR/90-verify.sh" ;;' "Menu option 7 must be wired"
assert_contains "$SELECTOR" '12\) run_sector "\$SECTOR_DIR/25-hostname.sh" ;;' "Menu option 12 must be wired"
assert_contains "$SELECTOR" '13\) run_sector "\$SECTOR_DIR/11-ssh-key-rotate.sh" ;;' "Menu option 13 must be wired"
assert_contains "$SELECTOR" '14\) run_unit_tests ;;' "Menu option 14 must be wired"
assert_contains "$SELECTOR" '15\) run_sector "\$SECTOR_DIR/95-compliance-check.sh" ;;' "Menu option 15 must be wired"
assert_contains "$SELECTOR" '16\) restart_now ;;' "Menu option 16 must be wired"
assert_contains "$SELECTOR" '17\) run_sector "\$SECTOR_DIR/05-update-kit.sh" ;;' "Menu option 17 must be wired"
assert_contains "$SELECTOR" '18\) run_sector "\$SECTOR_DIR/30-ping-policy.sh" ;;' "Menu option 18 must be wired"
assert_contains "$SELECTOR" 'Run another selector\? \(Y/n\): ' "Selector should default follow-up prompt to yes"

pass "Selector menu options"

