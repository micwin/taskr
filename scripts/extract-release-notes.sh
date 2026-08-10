#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 VERSION CHANGELOG" >&2
  exit 2
fi

release_version="$1"
changelog="$2"

awk -v header="## [${release_version}]" '
  index($0, header) == 1 { found = 1; next }
  found && /^## \[/ { exit }
  found { print }
  END { if (!found) exit 1 }
' "${changelog}"
