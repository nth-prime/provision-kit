#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

PING_SECTOR="$ROOT_DIR/sectors/30-ping-policy.sh"

assert_file_exists "$PING_SECTOR" "Ping policy sector must exist"
assert_contains "$PING_SECTOR" 'ALLOW_PING' "Ping policy sector must support config default"
assert_contains "$PING_SECTOR" '/etc/sysctl.d/99-provision-ping.conf' "Ping policy sector must persist sysctl settings"
assert_contains "$PING_SECTOR" 'sysctl --system' "Ping policy sector must apply sysctl settings"
assert_contains "$PING_SECTOR" 'mark_done 30-ping-policy.done' "Ping policy sector must write completion marker"

pass "Ping policy sector"

