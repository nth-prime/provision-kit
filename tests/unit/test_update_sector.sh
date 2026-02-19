#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

UPDATE_SECTOR="$ROOT_DIR/sectors/05-update-kit.sh"

assert_file_exists "$UPDATE_SECTOR" "Update sector must exist"
assert_contains "$UPDATE_SECTOR" 'PROVISION_KIT_REPO_URL' "Update sector must support configurable repo URL"
assert_contains "$UPDATE_SECTOR" 'PROVISION_KIT_BRANCH' "Update sector must support configurable branch"
assert_contains "$UPDATE_SECTOR" 'curl -fsSL' "Update sector must download source archive"
assert_contains "$UPDATE_SECTOR" 'bash "\$SRC_DIR/install.sh"' "Update sector must run installer from extracted source"
assert_contains "$UPDATE_SECTOR" 'mark_done 05-update-kit.done' "Update sector must write completion marker"

pass "Update sector"

