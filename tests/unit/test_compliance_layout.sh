#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

assert_dir_exists "$ROOT_DIR/compliance" "Compliance root directory must exist"
assert_dir_exists "$ROOT_DIR/compliance/lib" "Compliance lib directory must exist"
assert_dir_exists "$ROOT_DIR/compliance/repairs" "Compliance repairs directory must exist"
assert_dir_exists "$ROOT_DIR/compliance/tests" "Compliance tests directory must exist"

assert_file_exists "$ROOT_DIR/compliance/lib/engine.sh" "Compliance engine must exist"
assert_file_exists "$ROOT_DIR/compliance/lib/checks.sh" "Compliance checks must exist"
assert_file_exists "$ROOT_DIR/compliance/repairs/repair-config-var.sh" "Compliance repair strategy for config vars must exist"
assert_file_exists "$ROOT_DIR/compliance/repairs/repair-sshd-runtime.sh" "Compliance repair strategy for sshd runtime must exist"
assert_file_exists "$ROOT_DIR/compliance/repairs/repair-ssh-auth.sh" "Compliance repair strategy for SSH auth must exist"
assert_file_exists "$ROOT_DIR/compliance/repairs/repair-ssh-access-policy.sh" "Compliance repair strategy for SSH access policy must exist"
assert_file_exists "$ROOT_DIR/compliance/repairs/repair-unattended-upgrades.sh" "Compliance repair strategy for unattended upgrades must exist"
assert_file_exists "$ROOT_DIR/compliance/repairs/repair-sudoers-nopasswd.sh" "Compliance repair strategy for sudoers NOPASSWD policy must exist"
assert_file_exists "$ROOT_DIR/compliance/tests/test_check_repair_mapping.sh" "Compliance mapping test must exist"

pass "Compliance layout"
