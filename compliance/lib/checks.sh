#!/usr/bin/env bash
set -euo pipefail

PROVISION_BASE_DIR="${PROVISION_BASE_DIR:-/opt/provision-kit}"
COMPLIANCE_REPAIRS_DIR="$PROVISION_BASE_DIR/compliance/repairs"

COMPLIANCE_LAST_DETAIL=""

set_compliance_detail() {
  COMPLIANCE_LAST_DETAIL="$1"
}

normalize_host_cidr() {
  local cidr="$1"
  case "$cidr" in
    */32 | */128) echo "${cidr%/*}" ;;
    *) echo "$cidr" ;;
  esac
}

capture_compliance_state() {
  mkdir -p /run/sshd
  SSHD_EFFECTIVE="$(sshd -T 2>/dev/null || true)"
  UFW_STATUS="$(ufw status 2>/dev/null || true)"
  UFW_VERBOSE="$(ufw status verbose 2>/dev/null || true)"
}

check_cfg_ssh_port_present() {
  if [[ -n "${SSH_PORT:-}" ]]; then
    set_compliance_detail "Observed SSH_PORT='${SSH_PORT}'."
    return 0
  fi
  set_compliance_detail "SSH_PORT is unset or empty in $CONFIG."
  return 1
}

check_cfg_enforce_tailscale_present() {
  if [[ -n "${ENFORCE_TAILSCALE_ACCESS:-}" ]]; then
    set_compliance_detail "Observed ENFORCE_TAILSCALE_ACCESS='${ENFORCE_TAILSCALE_ACCESS}'."
    return 0
  fi
  set_compliance_detail "ENFORCE_TAILSCALE_ACCESS is unset or empty in $CONFIG."
  return 1
}

check_cfg_allow_public_whitelist_present() {
  if [[ -n "${SSH_ALLOW_PUBLIC_WHITELIST:-}" ]]; then
    set_compliance_detail "Observed SSH_ALLOW_PUBLIC_WHITELIST='${SSH_ALLOW_PUBLIC_WHITELIST}'."
    return 0
  fi
  set_compliance_detail "SSH_ALLOW_PUBLIC_WHITELIST is unset or empty in $CONFIG."
  return 1
}

check_cfg_whitelist_ipv4_present() {
  if [[ -v SSH_WHITELIST_IPV4 ]]; then
    set_compliance_detail "Observed SSH_WHITELIST_IPV4='${SSH_WHITELIST_IPV4}'."
    return 0
  fi
  set_compliance_detail "SSH_WHITELIST_IPV4 is missing in $CONFIG."
  return 1
}

check_cfg_whitelist_ipv6_present() {
  if [[ -v SSH_WHITELIST_IPV6 ]]; then
    set_compliance_detail "Observed SSH_WHITELIST_IPV6='${SSH_WHITELIST_IPV6}'."
    return 0
  fi
  set_compliance_detail "SSH_WHITELIST_IPV6 is missing in $CONFIG."
  return 1
}

check_enforce_tailscale_enabled() {
  if [[ "${ENFORCE_TAILSCALE_ACCESS:-0}" == "1" ]]; then
    set_compliance_detail "Expected ENFORCE_TAILSCALE_ACCESS=1, observed ${ENFORCE_TAILSCALE_ACCESS}."
    return 0
  fi
  set_compliance_detail "Expected ENFORCE_TAILSCALE_ACCESS=1, observed '${ENFORCE_TAILSCALE_ACCESS:-unset}'."
  return 1
}

check_ssh_port_valid() {
  if [[ "${SSH_PORT:-}" =~ ^[0-9]+$ ]] && (( SSH_PORT >= 1 && SSH_PORT <= 65535 )); then
    set_compliance_detail "Expected numeric port in 1-65535, observed SSH_PORT=${SSH_PORT}."
    return 0
  fi
  set_compliance_detail "Expected numeric port in 1-65535, observed SSH_PORT='${SSH_PORT:-unset}'."
  return 1
}

check_sshd_t_executes() {
  mkdir -p /run/sshd
  if sshd -T >/dev/null 2>&1; then
    set_compliance_detail "sshd -T executed successfully."
    return 0
  fi
  set_compliance_detail "sshd -T failed. Inspect /etc/ssh/sshd_config and drop-ins."
  return 1
}

check_root_login_disabled() {
  capture_compliance_state
  local observed
  observed="$(echo "$SSHD_EFFECTIVE" | awk '/^permitrootlogin /{print $2}' | head -n1)"
  if [[ "$observed" == "no" ]]; then
    set_compliance_detail "Expected permitrootlogin no, observed '${observed}'."
    return 0
  fi
  set_compliance_detail "Expected permitrootlogin no, observed '${observed:-unset}'."
  return 1
}

check_password_auth_disabled() {
  capture_compliance_state
  local observed
  observed="$(echo "$SSHD_EFFECTIVE" | awk '/^passwordauthentication /{print $2}' | head -n1)"
  if [[ "$observed" == "no" ]]; then
    set_compliance_detail "Expected passwordauthentication no, observed '${observed}'."
    return 0
  fi
  set_compliance_detail "Expected passwordauthentication no, observed '${observed:-unset}'."
  return 1
}

check_sshd_port_matches_config() {
  capture_compliance_state
  local observed
  observed="$(echo "$SSHD_EFFECTIVE" | awk '/^port /{print $2}' | head -n1)"
  if [[ "$observed" == "${SSH_PORT:-}" ]]; then
    set_compliance_detail "Expected sshd port ${SSH_PORT}, observed '${observed}'."
    return 0
  fi
  set_compliance_detail "Expected sshd port ${SSH_PORT:-unset}, observed '${observed:-unset}'."
  return 1
}

check_ufw_default_deny_incoming() {
  capture_compliance_state
  if echo "$UFW_VERBOSE" | grep -Eq '^Default: deny \(incoming\)'; then
    set_compliance_detail "Expected UFW default deny incoming, observed matching default."
    return 0
  fi
  set_compliance_detail "Expected UFW default deny incoming. Raw line: $(echo "$UFW_VERBOSE" | grep -E '^Default:' || echo 'missing')."
  return 1
}

check_ufw_tailscale_ssh_rule() {
  capture_compliance_state
  if echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp([[:space:]]+\(v6\))?[[:space:]]+on[[:space:]]+tailscale0[[:space:]]+ALLOW( IN)?[[:space:]]+Anywhere( \(v6\))?[[:space:]]*$" >/dev/null; then
    set_compliance_detail "Expected tailscale0 SSH allow rule on port ${SSH_PORT}; observed rule present."
    return 0
  fi
  set_compliance_detail "Expected tailscale0 SSH allow rule on port ${SSH_PORT:-unset}; observed missing. Raw status: $(echo "$UFW_STATUS" | tr '\n' ';')."
  return 1
}

check_ufw_whitelist_rules() {
  capture_compliance_state
  if [[ "${SSH_ALLOW_PUBLIC_WHITELIST:-0}" != "1" ]]; then
    set_compliance_detail "Whitelist disabled (SSH_ALLOW_PUBLIC_WHITELIST=${SSH_ALLOW_PUBLIC_WHITELIST:-0}); check skipped."
    return 0
  fi

  local missing=()
  local cidr host
  for cidr in ${SSH_WHITELIST_IPV4:-}; do
    host="$(normalize_host_cidr "$cidr")"
      if ! echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp[[:space:]]+ALLOW( IN)?[[:space:]]+(${cidr}|${host})[[:space:]]*$" >/dev/null; then
      missing+=("$cidr")
    fi
  done
  for cidr in ${SSH_WHITELIST_IPV6:-}; do
    host="$(normalize_host_cidr "$cidr")"
      if ! echo "$UFW_STATUS" | grep -Ei "^[[:space:]]*${SSH_PORT}/tcp[[:space:]]+ALLOW( IN)?[[:space:]]+(${cidr}|${host})[[:space:]]*$" >/dev/null; then
      missing+=("$cidr")
    fi
  done

  if (( ${#missing[@]} == 0 )); then
    set_compliance_detail "Expected whitelist rules were found for configured CIDRs."
    return 0
  fi

  set_compliance_detail "Missing whitelist rules for: ${missing[*]}. Raw status: $(echo "$UFW_STATUS" | tr '\n' ';')."
  return 1
}

check_unattended_upgrades_enabled_active() {
  local enabled active
  enabled="$(systemctl is-enabled unattended-upgrades 2>/dev/null || true)"
  active="$(systemctl is-active unattended-upgrades 2>/dev/null || true)"
  if [[ "$enabled" == "enabled" && "$active" == "active" ]]; then
    set_compliance_detail "Expected unattended-upgrades enabled/active, observed enabled=$enabled active=$active."
    return 0
  fi
  set_compliance_detail "Expected unattended-upgrades enabled/active, observed enabled='${enabled:-unknown}' active='${active:-unknown}'."
  return 1
}

list_compliance_checks() {
  cat <<EOF
cfg_ssh_port_present|Config variable SSH_PORT present|check_cfg_ssh_port_present|$COMPLIANCE_REPAIRS_DIR/repair-config-var.sh|SSH_PORT 22
cfg_enforce_tailscale_present|Config variable ENFORCE_TAILSCALE_ACCESS present|check_cfg_enforce_tailscale_present|$COMPLIANCE_REPAIRS_DIR/repair-config-var.sh|ENFORCE_TAILSCALE_ACCESS 1
cfg_allow_public_whitelist_present|Config variable SSH_ALLOW_PUBLIC_WHITELIST present|check_cfg_allow_public_whitelist_present|$COMPLIANCE_REPAIRS_DIR/repair-config-var.sh|SSH_ALLOW_PUBLIC_WHITELIST 1
cfg_whitelist_ipv4_present|Config variable SSH_WHITELIST_IPV4 present|check_cfg_whitelist_ipv4_present|$COMPLIANCE_REPAIRS_DIR/repair-config-var.sh|SSH_WHITELIST_IPV4 __EMPTY__
cfg_whitelist_ipv6_present|Config variable SSH_WHITELIST_IPV6 present|check_cfg_whitelist_ipv6_present|$COMPLIANCE_REPAIRS_DIR/repair-config-var.sh|SSH_WHITELIST_IPV6 __EMPTY__
tailscale_enforced|ENFORCE_TAILSCALE_ACCESS is enabled|check_enforce_tailscale_enabled|$COMPLIANCE_REPAIRS_DIR/repair-config-var.sh|ENFORCE_TAILSCALE_ACCESS 1
ssh_port_valid|SSH_PORT is valid|check_ssh_port_valid|$COMPLIANCE_REPAIRS_DIR/repair-config-var.sh|SSH_PORT 22
sshd_t_executes|sshd -T executes successfully|check_sshd_t_executes|$COMPLIANCE_REPAIRS_DIR/repair-sshd-runtime.sh|
ssh_root_disabled|Root SSH login disabled|check_root_login_disabled|$COMPLIANCE_REPAIRS_DIR/repair-ssh-auth.sh|
ssh_password_disabled|SSH password authentication disabled|check_password_auth_disabled|$COMPLIANCE_REPAIRS_DIR/repair-ssh-auth.sh|
sshd_port_matches|sshd port matches SSH_PORT|check_sshd_port_matches_config|$COMPLIANCE_REPAIRS_DIR/repair-ssh-access-policy.sh|
ufw_default_deny|UFW default deny incoming|check_ufw_default_deny_incoming|$COMPLIANCE_REPAIRS_DIR/repair-ssh-access-policy.sh|
ufw_tailscale_ssh|UFW allows SSH on tailscale0|check_ufw_tailscale_ssh_rule|$COMPLIANCE_REPAIRS_DIR/repair-ssh-access-policy.sh|
ufw_whitelist_rules|UFW whitelist rules align with config|check_ufw_whitelist_rules|$COMPLIANCE_REPAIRS_DIR/repair-ssh-access-policy.sh|
unattended_upgrades|Unattended upgrades enabled and active|check_unattended_upgrades_enabled_active|$COMPLIANCE_REPAIRS_DIR/repair-unattended-upgrades.sh|
EOF
}
