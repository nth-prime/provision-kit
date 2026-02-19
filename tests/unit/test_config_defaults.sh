#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

CONFIG_EXAMPLE="$ROOT_DIR/config/provision.conf.example"

assert_file_exists "$CONFIG_EXAMPLE" "Config example must exist"

assert_contains "$CONFIG_EXAMPLE" '^SSH_PORT=22$' "Default SSH port must be set"
assert_contains "$CONFIG_EXAMPLE" '^ENFORCE_TAILSCALE_ACCESS=1$' "Tailscale enforcement must default to enabled"
assert_contains "$CONFIG_EXAMPLE" '^SSH_ALLOW_PUBLIC_WHITELIST=1$' "Whitelist toggle default must exist"
assert_contains "$CONFIG_EXAMPLE" '^UFW_FORCE_RESET=0$' "UFW reset must default to off"

pass "Config defaults"

