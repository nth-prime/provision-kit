#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

USER_SSH="$ROOT_DIR/sectors/10-user-ssh.sh"
ROTATE_SSH="$ROOT_DIR/sectors/11-ssh-key-rotate.sh"

assert_file_exists "$USER_SSH" "User SSH sector must exist"
assert_file_exists "$ROTATE_SSH" "SSH key rotate sector must exist"

assert_contains "$USER_SSH" 'ssh-keygen -t ed25519' "User SSH sector must provide key generation instruction"
assert_contains "$USER_SSH" 'Get-Content \$env:USERPROFILE' "User SSH sector must provide Windows public key path instruction"

assert_contains "$ROTATE_SSH" 'ssh-keygen -t ed25519' "Rotate sector must provide key generation instruction"
assert_contains "$ROTATE_SSH" 'Get-Content \$env:USERPROFILE' "Rotate sector must provide Windows public key path instruction"

pass "Public key help instructions"

