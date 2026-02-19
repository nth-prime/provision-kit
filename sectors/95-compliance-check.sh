#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"

fail_count=0

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1"
  fail_count=$((fail_count + 1))
}

debug() {
  echo "DEBUG: $1"
}

normalize_host_cidr() {
  local cidr="$1"
  case "$cidr" in
    */32|*/128) echo "${cidr%/*}" ;;
    *) echo "$cidr" ;;
  esac
}

check_required_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    fail "Missing required config variable: $name"
  else
    pass "Config variable present: $name"
  fi
}

echo "Running compliance checks..."

check_required_var "SSH_PORT"
check_required_var "ENFORCE_TAILSCALE_ACCESS"
check_required_var "SSH_ALLOW_PUBLIC_WHITELIST"
check_required_var "SSH_WHITELIST_IPV4"

if [[ -v SSH_WHITELIST_IPV6 ]]; then
  pass "Config variable present: SSH_WHITELIST_IPV6"
else
  fail "Missing required config variable: SSH_WHITELIST_IPV6"
fi

if [[ "${ENFORCE_TAILSCALE_ACCESS:-0}" == "1" ]]; then
  pass "ENFORCE_TAILSCALE_ACCESS is enabled"
else
  fail "ENFORCE_TAILSCALE_ACCESS must be 1"
fi

if [[ ! "${SSH_PORT:-}" =~ ^[0-9]+$ ]] || (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
  fail "SSH_PORT must be numeric and between 1-65535"
else
  pass "SSH_PORT is valid"
fi

mkdir -p /run/sshd
if sshd -T >/dev/null 2>&1; then
  pass "sshd -T executed successfully"
else
  fail "sshd -T failed"
fi

SSHD_EFFECTIVE="$(sshd -T 2>/dev/null || true)"
UFW_STATUS="$(ufw status 2>/dev/null || true)"
UFW_VERBOSE="$(ufw status verbose 2>/dev/null || true)"

debug "sshd permitrootlogin: $(echo "$SSHD_EFFECTIVE" | awk '/^permitrootlogin /{print $2}')"
debug "sshd passwordauthentication: $(echo "$SSHD_EFFECTIVE" | awk '/^passwordauthentication /{print $2}')"
debug "sshd port: $(echo "$SSHD_EFFECTIVE" | awk '/^port /{print $2}' | head -n1)"

if echo "$SSHD_EFFECTIVE" | grep -Eq '^permitrootlogin no$'; then
  pass "Root SSH login disabled"
else
  fail "Root SSH login is not disabled"
fi

if echo "$SSHD_EFFECTIVE" | grep -Eq '^passwordauthentication no$'; then
  pass "SSH password authentication disabled"
else
  fail "SSH password authentication is not disabled"
fi

if echo "$SSHD_EFFECTIVE" | grep -Eq "^port ${SSH_PORT}$"; then
  pass "SSHD port matches SSH_PORT"
else
  fail "SSHD port does not match SSH_PORT"
fi

if echo "$UFW_VERBOSE" | grep -Eq '^Default: deny \(incoming\)'; then
  pass "UFW default deny incoming"
else
  fail "UFW default incoming policy is not deny"
fi

debug "ufw tailscale candidates:"
echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp.*tailscale0" || true

if echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp([[:space:]]+\(v6\))?[[:space:]]+on[[:space:]]+tailscale0[[:space:]]+ALLOW IN[[:space:]]+Anywhere( \(v6\))?$" >/dev/null; then
  pass "UFW allows SSH on tailscale0"
else
  fail "UFW rule for SSH on tailscale0 missing"
fi

if [[ "${SSH_ALLOW_PUBLIC_WHITELIST:-0}" == "1" ]]; then
  missing_whitelist=0
  for cidr in ${SSH_WHITELIST_IPV4:-}; do
    host="$(normalize_host_cidr "$cidr")"
    debug "checking IPv4 whitelist rule for: $cidr (host form: $host)"
    if echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp[[:space:]]+ALLOW IN[[:space:]]+(${cidr}|${host})$" >/dev/null; then
      pass "Whitelist IPv4 rule present: $cidr"
    else
      fail "Whitelist IPv4 rule missing: $cidr"
      missing_whitelist=1
    fi
  done
  for cidr in ${SSH_WHITELIST_IPV6:-}; do
    host="$(normalize_host_cidr "$cidr")"
    debug "checking IPv6 whitelist rule for: $cidr (host form: $host)"
    if echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp[[:space:]]+ALLOW IN[[:space:]]+(${cidr}|${host})$" >/dev/null; then
      pass "Whitelist IPv6 rule present: $cidr"
    else
      fail "Whitelist IPv6 rule missing: $cidr"
      missing_whitelist=1
    fi
  done
  if [[ "$missing_whitelist" == "0" ]]; then
    pass "Whitelist enforcement rules checked"
  fi
fi

if systemctl is-enabled unattended-upgrades >/dev/null 2>&1 && systemctl is-active unattended-upgrades >/dev/null 2>&1; then
  pass "Unattended upgrades enabled and active"
else
  fail "Unattended upgrades is not enabled and active"
fi

if (( fail_count > 0 )); then
  echo "Compliance check failed with $fail_count issue(s)."
  exit 1
fi

echo "Compliance check passed."
mark_done 95-compliance-check.done
