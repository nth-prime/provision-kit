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
assert_contains "$CONFIG_EXAMPLE" '^ADMIN_SUDO_PASSWORD=""$' "Admin sudo password should default empty for first-run prompt"
assert_contains "$CONFIG_EXAMPLE" '^PROVISION_KIT_REPO_URL="https://github\.com/nth-prime/provision-kit"$' "Default update repo URL must exist"
assert_contains "$CONFIG_EXAMPLE" '^PROVISION_KIT_BRANCH="main"$' "Default update branch must exist"
assert_contains "$CONFIG_EXAMPLE" '^ALLOW_PING=0$' "Ping policy must default to disabled"
assert_contains "$CONFIG_EXAMPLE" '^ALLOW_CLOUD_INIT_ROOT_NOPASSWD=1$' "Sudoers strict mode must default permissive"

pass "Config defaults"

