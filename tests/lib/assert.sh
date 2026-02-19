#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $1"
  exit 1
}

pass() {
  echo "PASS: $1"
}

assert_file_exists() {
  local file="$1"
  local msg="$2"
  [[ -f "$file" ]] || fail "$msg (missing: $file)"
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local msg="$3"
  grep -Eq "$pattern" "$file" || fail "$msg (pattern: $pattern in $file)"
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local msg="$3"
  if grep -Eq "$pattern" "$file"; then
    fail "$msg (unexpected pattern: $pattern in $file)"
  fi
}

