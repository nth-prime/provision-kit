#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root

cat <<'EOF'
Selector Guide (What + Why)

1) Edit Config
What: Opens /etc/provision-kit/provision.conf for editing.
Why: Set policy before applying sectors.

2) Run Recommended Sequence (optional)
What: Runs core sectors in secure order.
Why: Fast baseline setup on fresh machines.

3) Tailscale Bootstrap
What: Installs and connects Tailscale.
Why: Ensure trusted management path first.

4) Admin User + SSH Setup
What: Creates admin user, sudo group, SSH key auth.
Why: Establishes key-based admin access.

5) SSH Access Policy
What: Applies sshd and UFW rules from config.
Why: Enforces root/password-off and inbound restrictions.

6) Baseline OS
What: Updates packages, enables unattended upgrades and time sync.
Why: Reduces exposure to known vulnerabilities.

7) Verify Posture
What: Prints current host security state.
Why: Quick operational snapshot after changes.

8) Show Status
What: Displays completion markers and quick checks.
Why: See what has already been applied.

9) Backup SSH/UFW/Provision Config
What: Saves runtime configs under /var/backups/provision-kit.
Why: Recovery point before risky edits.

10) Reset Completion Markers
What: Removes /var/lib/provision-kit/*.done markers.
Why: Re-run workflow tracking from a clean slate.

11) Print Effective Config
What: Prints active provision.conf values (non-comment lines).
Why: Confirm what policy values are in force.

12) Change Server Hostname
What: Updates hostname via hostnamectl.
Why: Standardize naming and inventory.

13) Rotate User SSH Key
What: Replace/remove/add user authorized keys safely.
Why: Key hygiene and access lifecycle management.

14) Run Unit Tests
What: Executes repository syntax and unit test suite.
Why: Validate script integrity after updates.

15) Enforce Compliance Check
What: Runs check/repair compliance pipeline.
Why: Confirm hardening requirements are met.

16) Restart Machine Now
What: Immediate system reboot.
Why: Apply pending service/kernel state changes.

17) Update Provision Kit from GitHub
What: Downloads configured branch and reinstalls kit.
Why: Apply latest fixes/features to installed copy.

18) Toggle Ping Policy
What: Enables/disables ICMP echo replies and persists sysctl.
Why: Control discoverability/network policy stance.

19) Repair SSH Auth Override
What: Re-applies SSH auth lock settings and restarts SSH.
Why: Recover from drift where password auth reappears.

20) Guided Posture Audit (Manual)
What: Step-by-step manual verification with explanations.
Why: Human-auditable validation of host posture.

21) Selector Guide
What: Prints this concise selector reference.
Why: Helps operators choose the right action safely.
EOF

mark_done 92-selector-guide.done
