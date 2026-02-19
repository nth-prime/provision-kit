#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

SELECTOR="$ROOT_DIR/provision"

assert_file_exists "$SELECTOR" "Selector script must exist"
assert_contains "$SELECTOR" 'ensure_admin_password_configured' "Selector must include admin password bootstrap guard"
assert_contains "$SELECTOR" 'prompt_and_set_admin_password' "Selector must include password prompt helper"
assert_contains "$SELECTOR" 'ADMIN_SUDO_PASSWORD has been set in config' "Selector must confirm password persistence"

pass "Selector password bootstrap"

