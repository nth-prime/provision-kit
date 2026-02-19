#!/usr/bin/env bash
set -euo pipefail

COMPLIANCE_FAIL_COUNT=0
COMPLIANCE_VERBOSE="${COMPLIANCE_VERBOSE:-0}"

compliance_pass() {
  echo "PASS: $1"
}

compliance_fail() {
  echo "FAIL: $1"
  COMPLIANCE_FAIL_COUNT=$((COMPLIANCE_FAIL_COUNT + 1))
}

compliance_debug() {
  if [[ "$COMPLIANCE_VERBOSE" == "1" ]]; then
    echo "DEBUG: $1"
  fi
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
    compliance_fail "Missing required config variable: $name"
  else
    compliance_pass "Config variable present: $name"
  fi
}

show_raw_state() {
  mkdir -p /run/sshd
  echo "=== RAW: sshd -T ==="
  sshd -T 2>/dev/null | egrep 'permitrootlogin|passwordauthentication|port|maxauthtries|maxsessions' || true
  echo
  echo "=== RAW: ufw status verbose ==="
  ufw status verbose || true
  echo
  echo "=== RAW: ufw status ==="
  ufw status || true
  echo
  echo "=== RAW: unattended-upgrades ==="
  systemctl is-enabled unattended-upgrades || true
  systemctl is-active unattended-upgrades || true
}

run_compliance_checks() {
  COMPLIANCE_FAIL_COUNT=0

  echo "Running compliance checks..."
  if [[ "$COMPLIANCE_VERBOSE" == "1" ]]; then
    echo "Mode: verbose walk-through"
  else
    echo "Mode: standard"
  fi

  check_required_var "SSH_PORT"
  check_required_var "ENFORCE_TAILSCALE_ACCESS"
  check_required_var "SSH_ALLOW_PUBLIC_WHITELIST"
  check_required_var "SSH_WHITELIST_IPV4"

  if [[ -v SSH_WHITELIST_IPV6 ]]; then
    compliance_pass "Config variable present: SSH_WHITELIST_IPV6"
  else
    compliance_fail "Missing required config variable: SSH_WHITELIST_IPV6"
  fi

  if [[ "${ENFORCE_TAILSCALE_ACCESS:-0}" == "1" ]]; then
    compliance_pass "ENFORCE_TAILSCALE_ACCESS is enabled"
  else
    compliance_fail "ENFORCE_TAILSCALE_ACCESS must be 1"
  fi

  if [[ ! "${SSH_PORT:-}" =~ ^[0-9]+$ ]] || (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
    compliance_fail "SSH_PORT must be numeric and between 1-65535"
  else
    compliance_pass "SSH_PORT is valid"
  fi

  mkdir -p /run/sshd
  if sshd -T >/dev/null 2>&1; then
    compliance_pass "sshd -T executed successfully"
  else
    compliance_fail "sshd -T failed"
  fi

  SSHD_EFFECTIVE="$(sshd -T 2>/dev/null || true)"
  UFW_STATUS="$(ufw status 2>/dev/null || true)"
  UFW_VERBOSE="$(ufw status verbose 2>/dev/null || true)"

  compliance_debug "sshd permitrootlogin: $(echo "$SSHD_EFFECTIVE" | awk '/^permitrootlogin /{print $2}')"
  compliance_debug "sshd passwordauthentication: $(echo "$SSHD_EFFECTIVE" | awk '/^passwordauthentication /{print $2}')"
  compliance_debug "sshd port: $(echo "$SSHD_EFFECTIVE" | awk '/^port /{print $2}' | head -n1)"

  if echo "$SSHD_EFFECTIVE" | grep -Eq '^permitrootlogin no$'; then
    compliance_pass "Root SSH login disabled"
  else
    compliance_fail "Root SSH login is not disabled"
  fi

  if echo "$SSHD_EFFECTIVE" | grep -Eq '^passwordauthentication no$'; then
    compliance_pass "SSH password authentication disabled"
  else
    compliance_fail "SSH password authentication is not disabled"
  fi

  if echo "$SSHD_EFFECTIVE" | grep -Eq "^port ${SSH_PORT}$"; then
    compliance_pass "SSHD port matches SSH_PORT"
  else
    compliance_fail "SSHD port does not match SSH_PORT"
  fi

  if echo "$UFW_VERBOSE" | grep -Eq '^Default: deny \(incoming\)'; then
    compliance_pass "UFW default deny incoming"
  else
    compliance_fail "UFW default incoming policy is not deny"
  fi

  compliance_debug "ufw tailscale candidates:"
  if [[ "$COMPLIANCE_VERBOSE" == "1" ]]; then
    echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp.*tailscale0" || true
  fi

  if echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp([[:space:]]+\(v6\))?[[:space:]]+on[[:space:]]+tailscale0[[:space:]]+ALLOW( IN)?[[:space:]]+Anywhere( \(v6\))?$" >/dev/null; then
    compliance_pass "UFW allows SSH on tailscale0"
  else
    compliance_fail "UFW rule for SSH on tailscale0 missing"
  fi

  if [[ "${SSH_ALLOW_PUBLIC_WHITELIST:-0}" == "1" ]]; then
    missing_whitelist=0
    for cidr in ${SSH_WHITELIST_IPV4:-}; do
      host="$(normalize_host_cidr "$cidr")"
      compliance_debug "checking IPv4 whitelist rule for: $cidr (host form: $host)"
      if echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp[[:space:]]+ALLOW( IN)?[[:space:]]+(${cidr}|${host})$" >/dev/null; then
        compliance_pass "Whitelist IPv4 rule present: $cidr"
      else
        compliance_fail "Whitelist IPv4 rule missing: $cidr"
        missing_whitelist=1
      fi
    done
    for cidr in ${SSH_WHITELIST_IPV6:-}; do
      host="$(normalize_host_cidr "$cidr")"
      compliance_debug "checking IPv6 whitelist rule for: $cidr (host form: $host)"
      if echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp[[:space:]]+ALLOW( IN)?[[:space:]]+(${cidr}|${host})$" >/dev/null; then
        compliance_pass "Whitelist IPv6 rule present: $cidr"
      else
        compliance_fail "Whitelist IPv6 rule missing: $cidr"
        missing_whitelist=1
      fi
    done
    if [[ "$missing_whitelist" == "0" ]]; then
      compliance_pass "Whitelist enforcement rules checked"
    fi
  fi

  if systemctl is-enabled unattended-upgrades >/dev/null 2>&1 && systemctl is-active unattended-upgrades >/dev/null 2>&1; then
    compliance_pass "Unattended upgrades enabled and active"
  else
    compliance_fail "Unattended upgrades is not enabled and active"
  fi

  if (( COMPLIANCE_FAIL_COUNT > 0 )); then
    echo "Compliance check failed with $COMPLIANCE_FAIL_COUNT issue(s)."
    return 1
  fi

  echo "Compliance check passed."
  return 0
}

