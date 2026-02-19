#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

UPDATE_SECTOR="$ROOT_DIR/sectors/05-update-kit.sh"
INSTALLER="$ROOT_DIR/install.sh"

assert_file_exists "$UPDATE_SECTOR" "Update sector must exist"
assert_file_exists "$INSTALLER" "Installer must exist"
assert_contains "$UPDATE_SECTOR" 'PROVISION_KIT_REPO_URL' "Update sector must support configurable repo URL"
assert_contains "$UPDATE_SECTOR" 'PROVISION_KIT_BRANCH' "Update sector must support configurable branch"
assert_contains "$UPDATE_SECTOR" 'curl -fsSL' "Update sector must download source archive"
assert_contains "$UPDATE_SECTOR" '\(cd "\$SRC_DIR" && bash "\./install.sh"\)' "Update sector must run installer from extracted source directory"
assert_contains "$UPDATE_SECTOR" 'mark_done 05-update-kit.done' "Update sector must write completion marker"
assert_contains "$INSTALLER" 'SCRIPT_DIR=' "Installer must derive its own source directory"
assert_contains "$INSTALLER" 'find "\$SCRIPT_DIR"' "Installer must copy from script directory, not caller cwd"

pass "Update sector"
