#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root

apt-get update
apt-get upgrade -y
apt-get install -y unattended-upgrades ca-certificates curl wget acl

systemctl enable --now unattended-upgrades

if systemctl list-unit-files | grep -q '^systemd-timesyncd'; then
  systemctl enable --now systemd-timesyncd
else
  apt-get install -y chrony
  systemctl enable --now chrony
fi

mark_done 20-baseline-os.done
