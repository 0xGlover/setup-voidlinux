#!/usr/bin/env bash
set -Eeuo pipefail
mode="${1:---plan}"
[[ "$mode" == --plan || "$mode" == --apply ]] || { echo "Use --plan ou --apply"; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$root/scripts/theme.sh" nord "$mode"
