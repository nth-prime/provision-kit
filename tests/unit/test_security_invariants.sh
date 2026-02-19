#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/lib/assert.sh"

SSH_ACCESS="$ROOT_DIR/sectors/15-ssh-access.sh"
USER_SSH="$ROOT_DIR/sectors/10-user-ssh.sh"
ROTATE_SSH="$ROOT_DIR/sectors/11-ssh-key-rotate.sh"
COMPLIANCE_MODULE="$ROOT_DIR/compliance/lib/checks.sh"
SSH_REPAIR="$ROOT_DIR/sectors/16-ssh-auth-repair.sh"

assert_file_exists "$SSH_ACCESS" "SSH access sector must exist"
assert_file_exists "$USER_SSH" "User SSH sector must exist"
assert_file_exists "$ROTATE_SSH" "SSH key rotate sector must exist"
assert_file_exists "$COMPLIANCE_MODULE" "Compliance module must exist"
assert_file_exists "$SSH_REPAIR" "SSH auth repair sector must exist"

assert_contains "$SSH_ACCESS" 'PermitRootLogin no' "Root SSH login must remain disabled"
assert_contains "$SSH_ACCESS" 'PasswordAuthentication no' "SSH password auth must remain disabled"
assert_contains "$SSH_ACCESS" '99-provision-auth.conf' "SSH sector must apply final auth override drop-in"
assert_contains "$SSH_ACCESS" 'Port \$SSH_PORT' "SSHD must use configured SSH port"
assert_contains "$SSH_ACCESS" 'ENFORCE_TAILSCALE_ACCESS' "Tailscale enforcement gate must exist"
assert_contains "$SSH_ACCESS" 'ufw allow in on tailscale0' "SSH must be allowed on tailscale interface"
assert_contains "$COMPLIANCE_MODULE" 'passwordauthentication no' "Compliance checks must verify password SSH is disabled"
assert_contains "$SSH_REPAIR" 'PasswordAuthentication no' "SSH auth repair must enforce password authentication disabled"

assert_not_contains "$USER_SSH" 'NOPASSWD:ALL' "User sector must not grant NOPASSWD sudo"
assert_not_contains "$ROTATE_SSH" 'ssh-keygen -t' "Rotate sector must not generate private keys"

if grep -R -Eq 'NOPASSWD:ALL' "$ROOT_DIR/sectors" "$ROOT_DIR/compliance" 2>/dev/null; then
  fail "No sector/compliance script may grant NOPASSWD:ALL"
fi

if grep -R -Eq 'ssh-keygen[[:space:]]+-t' "$ROOT_DIR/sectors" "$ROOT_DIR/compliance" 2>/dev/null; then
  fail "No sector/compliance script may generate private keys server-side"
fi

pass "Security invariants"
