#!/usr/bin/env bash
set -euo pipefail
source /opt/provision-kit/lib/lib.sh
require_root
require_config
source "$CONFIG"
source /opt/provision-kit/compliance/lib/engine.sh

echo "Running compliance checks with repair prompts..."
if run_compliance_pipeline; then
  mark_done 95-compliance-check.done
  exit 0
fi

exit 1
