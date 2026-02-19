# Provision Kit

Agnostic secure server bootstrap framework with modular sectors, idempotent scripts, and opinionated SSH hardening.

## Security Defaults

- SSH key-only authentication (`PasswordAuthentication no`)
- Root SSH login disabled (`PermitRootLogin no`)
- SSH allowed on `tailscale0`
- Optional SSH public IP whitelist
- Firewall default deny inbound (`ufw`)
- No global `NOPASSWD` sudo policy
- Warns if default cloud user exists (example: `ubuntu`)

## Repository Layout

```text
provision-kit/
  provision                     # selector menu
  install.sh                    # installer
  lib/lib.sh                    # shared utilities
  compliance/
    lib/                        # compliance engine and checks
    repairs/                    # remediation scripts used by compliance checks
    tests/                      # compliance-specific mapping tests
  sectors/
    00-tailscale.sh
    05-update-kit.sh
    10-user-ssh.sh
    11-ssh-key-rotate.sh
    15-ssh-access.sh
    16-ssh-auth-repair.sh
    20-baseline-os.sh
    25-hostname.sh
    30-ping-policy.sh
    90-verify.sh
    95-compliance-check.sh
  config/
    provision.conf.example
```

Install target paths:

- `/opt/provision-kit/`
- `/etc/provision-kit/provision.conf`
- `/usr/local/bin/provision-kit` (symlink)

## Requirements

- Debian/Ubuntu-style host
- Root or `sudo` privileges
- `systemd`
- Internet access for package installs and Tailscale bootstrap

## Install

### Option 1: Clone and install

```bash
git clone https://github.com/nth-prime/provision-kit.git
cd provision-kit
sudo bash install.sh
```

### Option 2: One-liner from GitHub

```bash
set -euo pipefail
tmpdir="$(mktemp -d)"
curl -fsSL "https://github.com/nth-prime/provision-kit/archive/refs/heads/main.tar.gz" -o "$tmpdir/provision-kit.tar.gz"
tar -xzf "$tmpdir/provision-kit.tar.gz" -C "$tmpdir"
cd "$tmpdir/provision-kit-main"
sudo bash install.sh
```

After install:

```bash
provision-kit
```

## Versioning

- The installed version is stored in `/opt/provision-kit/VERSION`.
- The selector header shows the running version as `Provision Kit vX.Y.Z`.
- The update sector (`17`) reports the installed version after update.

Check version manually:

```bash
cat /opt/provision-kit/VERSION
```

## SSH Key Quickstart

Generate your key on your local machine (not on the server), then paste the public key line when prompted.

Linux/macOS:

```bash
ssh-keygen -t ed25519 -C "your-label"
cat ~/.ssh/id_ed25519.pub
```

Windows PowerShell:

```powershell
ssh-keygen -t ed25519 -C "your-label"
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
```

Use the full line that begins with `ssh-ed25519` (or `ssh-rsa`/`ssh-ecdsa`).

## Configuration

Config file path:

```text
/etc/provision-kit/provision.conf
```

Initial config is copied from `config/provision.conf.example` on first install.

Key settings:

- `SSH_PORT` (default `22`)
- `ENFORCE_TAILSCALE_ACCESS` (must be `1`)
- `SSH_ALLOW_PUBLIC_WHITELIST` (`1` or `0`)
- `SSH_WHITELIST_IPV4` (space-separated CIDRs)
- `SSH_WHITELIST_IPV6` (space-separated CIDRs)
- `DEFAULT_USER_NAME` (for warning checks)
- `ADMIN_SUDO_PASSWORD` (local sudo password policy for provisioned admin users)
- `UFW_FORCE_RESET` (`1` to clear all existing UFW rules before applying kit rules, default `0`)
- `PROVISION_KIT_REPO_URL` (GitHub repo URL for in-app updates)
- `PROVISION_KIT_BRANCH` (branch used by in-app updates)
- `ALLOW_PING` (`1` allow ICMP echo replies, `0` disable; default `0`)

Example:

```bash
SSH_PORT=22
ENFORCE_TAILSCALE_ACCESS=1
SSH_ALLOW_PUBLIC_WHITELIST=1
SSH_WHITELIST_IPV4="203.0.113.10/32 198.51.100.42/32"
SSH_WHITELIST_IPV6="2001:db8::1/128"
DEFAULT_USER_NAME="ubuntu"
ADMIN_SUDO_PASSWORD=""
UFW_FORCE_RESET=0
PROVISION_KIT_REPO_URL="https://github.com/nth-prime/provision-kit"
PROVISION_KIT_BRANCH="main"
ALLOW_PING=0
```

On first run, if `ADMIN_SUDO_PASSWORD` is empty, `provision-kit` will prompt you to set it and write it to `/etc/provision-kit/provision.conf` before allowing menu actions. Format: minimum 6 characters.

## Usage

Run selector:

```bash
provision-kit
```

Menu options:

1. Edit Config
2. Run Recommended Sequence (optional)
3. Tailscale Bootstrap
4. Admin User + SSH Setup
5. SSH Access Policy
6. Baseline OS
7. Verify Posture
8. Show Status
9. Backup SSH/UFW/Provision Config
10. Reset Completion Markers
11. Print Effective Config
12. Change Server Hostname
13. Rotate User SSH Key
14. Run Unit Tests
15. Enforce Compliance Check
16. Restart Machine Now
17. Update Provision Kit from GitHub
18. Toggle Ping Policy
19. Repair SSH Auth Override

Recommended sector order:

1. `00-tailscale.sh` - installs/connects Tailscale
2. `10-user-ssh.sh` - creates admin user, installs SSH public key
3. `15-ssh-access.sh` - applies SSH + firewall access policy
4. `20-baseline-os.sh` - updates system baseline packages/services
5. `90-verify.sh` - prints effective posture checks

All sectors are intended to be re-runnable. Completion markers are written under:

```text
/var/lib/provision-kit/
```

## What Each Sector Does

- `00-tailscale.sh`
  - Installs Tailscale if absent
  - Prompts for auth key if not already connected
- `05-update-kit.sh`
  - Downloads configured repo/branch tarball from GitHub
  - Re-runs installer from extracted source to update `/opt/provision-kit`
- `10-user-ssh.sh`
  - Creates admin user if missing
  - Adds user to `sudo` group
  - Sets local sudo password from `ADMIN_SUDO_PASSWORD`
  - Adds provided public key idempotently to `authorized_keys`
  - Warns if default cloud user exists
- `15-ssh-access.sh`
  - Writes `/etc/ssh/sshd_config.d/95-provision.conf`
  - Writes final auth override `/etc/ssh/sshd_config.d/99-provision-auth.conf`
  - Sets SSH daemon `Port` from `SSH_PORT`
  - Disables root/password SSH auth and limits forwarding/session knobs
  - Applies `ufw` deny-by-default inbound policy
  - Optionally resets UFW state only when `UFW_FORCE_RESET=1`
  - Allows SSH on `tailscale0`, plus optional whitelist
- `11-ssh-key-rotate.sh`
  - Backs up current `authorized_keys` before changes
  - Supports replacing all keys, removing one key, and adding a replacement key
  - Validates key format and enforces secure file ownership/permissions
- `16-ssh-auth-repair.sh`
  - Force-writes final SSH auth override with `PermitRootLogin no` and `PasswordAuthentication no`
  - Restarts SSH and prints effective auth values for troubleshooting
- `25-hostname.sh`
  - Changes system hostname with input validation
  - Uses `hostnamectl` and records completion marker
- `30-ping-policy.sh`
  - Enables/disables ICMP echo replies
  - Persists setting via `/etc/sysctl.d/99-provision-ping.conf`
- `20-baseline-os.sh`
  - Updates/upgrades packages
  - Enables unattended upgrades
  - Enables time sync service
- `90-verify.sh`
  - Prints Tailscale status, listening ports, effective SSHD config, UFW status, unattended-upgrades status
- `95-compliance-check.sh`
  - Runs compliance checks sequentially from `compliance/lib/checks.sh`
  - Stops on each failed check and prompts for `Repair`, `Ignore`, or `Abort`
  - Executes mapped repair strategies from `compliance/repairs/`
  - Exits non-zero if any issue is ignored or unresolved

## Security Invariants

This kit should not be modified to:

- Re-enable SSH password authentication
- Re-enable root SSH login
- Add global `%sudo NOPASSWD:ALL`
- Generate private keys on the server
- Allow SSH on all interfaces without Tailscale restriction or explicit whitelist

## Troubleshooting

- `Missing config: /etc/provision-kit/provision.conf`
  - Re-run `sudo bash install.sh` or create the file from the example.
- `Refusing to continue: ENFORCE_TAILSCALE_ACCESS must be 1`
  - Set `ENFORCE_TAILSCALE_ACCESS=1` in config.
- `sshd -t` fails
  - Validate existing SSH config includes and syntax before rerunning sector 15.
- SSH lockout risk
  - Ensure Tailscale is connected and your key is installed before applying sector 15.

## Testing

This repository includes a lightweight test harness under `tests/` and `compliance/tests/`:

- `tests/tester` - runs syntax checks, optional `shellcheck`, and unit tests
- Menu option `14` runs `tests/tester` directly from the installed kit
- `tests/unit/test_security_invariants.sh` - validates core security invariants
- `tests/unit/test_selector_menu.sh` - validates selector menu coverage and wiring
- `tests/unit/test_config_defaults.sh` - validates expected default config values
- `tests/unit/test_hostname_sector.sh` - validates hostname sector behavior and safeguards
- `tests/unit/test_compliance_sector.sh` - validates compliance sector wiring and guardrails
- `tests/unit/test_update_sector.sh` - validates updater sector behavior and wiring
- `tests/unit/test_ping_sector.sh` - validates ping policy sector behavior and wiring
- `tests/unit/test_selector_password_bootstrap.sh` - validates first-run admin password bootstrap behavior
- `tests/unit/test_pubkey_help.sh` - validates SSH public key helper guidance
- `tests/unit/test_versioning.sh` - validates VERSION usage/display
- `tests/unit/test_ssh_auth_repair_sector.sh` - validates SSH auth repair sector behavior
- `compliance/tests/test_check_repair_mapping.sh` - validates one-to-one check/repair mapping for compliance

Run tests on a Linux host:

```bash
chmod +x tests/tester tests/unit/*.sh tests/lib/assert.sh compliance/tests/*.sh
./tests/tester
```

Selector behavior:

- After each action, `Run another selector? (Y/n)` defaults to **Yes** when you press Enter.

Optional dependency:

- `shellcheck` (if present, linting is included automatically)

## Publishing Checklist

- Add a `LICENSE`
- Add CI shell linting (recommended: `shellcheck` + `bash -n`)
- Test end-to-end on a disposable VM before tagging a release
