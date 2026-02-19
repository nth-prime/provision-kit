#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

HOSTNAME_SECTOR="$ROOT_DIR/sectors/25-hostname.sh"

assert_file_exists "$HOSTNAME_SECTOR" "Hostname sector must exist"
assert_contains "$HOSTNAME_SECTOR" 'hostnamectl set-hostname' "Hostname sector must use hostnamectl"
assert_contains "$HOSTNAME_SECTOR" 'Invalid hostname\. Use 1-63 chars' "Hostname sector must validate input"
assert_contains "$HOSTNAME_SECTOR" 'mark_done 25-hostname.done' "Hostname sector must write completion marker"

pass "Hostname sector"

