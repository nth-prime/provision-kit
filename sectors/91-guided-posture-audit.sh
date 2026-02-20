#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"

step() {
  local title="$1"
  local intent="$2"
  local cmd="$3"
  local yn

  echo
  echo "=================================================="
  echo "$title"
  echo "Why this matters: $intent"
  echo "Command:"
  echo "  $cmd"
  read -rp "Run this step now? (Y/n/q): " yn
  if [[ "${yn:-Y}" =~ ^[qQ]$ ]]; then
    echo "Guided posture audit canceled."
    exit 0
  fi
  if [[ -z "$yn" || "$yn" =~ ^[yY]$ ]]; then
    eval "$cmd"
  else
    echo "Skipped."
  fi
}

echo "Guided Posture Audit"
echo "This runs manual verification commands step-by-step with explanations."

step \
  "Step 1: Install Paths and Version" \
  "Confirms selector symlink and installed payload location." \
  "ls -l /opt/provision-kit /etc/provision-kit/provision.conf /usr/local/bin/provision-kit; cat /opt/provision-kit/VERSION"

step \
  "Step 2: Effective Provision Config" \
  "Validates the policy values currently in effect." \
  "awk 'NF && \$1 !~ /^#/' /etc/provision-kit/provision.conf"

step \
  "Step 3: SSH Daemon Hardening" \
  "Checks effective SSH security settings (root/password auth off, forwarding restrictions)." \
  "mkdir -p /run/sshd; sshd -T | egrep 'port |permitrootlogin|passwordauthentication|kbdinteractiveauthentication|allowtcpforwarding|allowagentforwarding|maxauthtries|maxsessions'"

step \
  "Step 4: Firewall Rules" \
  "Ensures default deny inbound and expected SSH allow rules only." \
  "ufw status verbose"

step \
  "Step 5: Ping Policy" \
  "Confirms ICMP echo behavior matches ALLOW_PING policy." \
  "sysctl net.ipv4.icmp_echo_ignore_all; cat /etc/sysctl.d/99-provision-ping.conf"

step \
  "Step 6: Patch/Time Baseline Services" \
  "Validates unattended upgrades and active time synchronization service." \
  "systemctl is-enabled unattended-upgrades; systemctl is-active unattended-upgrades; systemctl is-enabled systemd-timesyncd 2>/dev/null || true; systemctl is-active systemd-timesyncd 2>/dev/null || true; systemctl is-enabled chrony 2>/dev/null || true; systemctl is-active chrony 2>/dev/null || true"

step \
  "Step 7: Tailscale and Listening Services" \
  "Checks tailnet attachment and that exposed listeners align with expected posture." \
  "tailscale ip -4; tailscale status; ss -tulpn | egrep '(:22|tailscaled|LISTEN)'"

step \
  "Step 8: User and Sudo Posture" \
  "Checks admin group membership, key file permissions, and NOPASSWD policy drift." \
  "id \"\${SUDO_USER:-root}\" 2>/dev/null || true; ls -l /etc/sudoers.d; grep -Rni 'NOPASSWD' /etc/sudoers /etc/sudoers.d 2>/dev/null || true"

echo
echo "Guided posture audit complete."
mark_done 91-guided-posture-audit.done
