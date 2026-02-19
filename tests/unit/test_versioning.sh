#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

assert_file_exists "$ROOT_DIR/VERSION" "VERSION file must exist"
assert_contains "$ROOT_DIR/VERSION" '^[0-9]+\.[0-9]+\.[0-9]+$' "VERSION must follow semver-like format"

assert_contains "$ROOT_DIR/provision" 'VERSION_FILE="\$BASE_DIR/VERSION"' "Selector must reference VERSION file"
assert_contains "$ROOT_DIR/provision" 'Provision Kit v\$VERSION' "Selector header must display version"

assert_contains "$ROOT_DIR/sectors/05-update-kit.sh" '/opt/provision-kit/VERSION' "Updater must report installed version"

pass "Versioning"

