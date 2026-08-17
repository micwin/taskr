#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 TASKR_ROOT [--since-ref REF|none]" >&2
  exit 2
}

[ "$#" -ge 1 ] || usage
root="$1"
shift
since_ref=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --since-ref)
      [ "$#" -ge 2 ] || usage
      since_ref="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[ -d "${root}" ] || { echo "collect-taskr-release-notes.sh: missing root ${root}" >&2; exit 2; }

tmp="$(mktemp)"
find "${root}" -type f \( -name milestone.md -o -name task.md -o -name subtask.md \) | sort | while IFS= read -r marker; do
  if [ -n "${since_ref}" ] && [ "${since_ref}" != "none" ] && git rev-parse --verify --quiet "${since_ref}" >/dev/null; then
    if git diff --quiet "${since_ref}..HEAD" -- "${marker}" 2>/dev/null; then
      continue
    fi
  fi
  status="$(awk -F': *' 'BEGIN{in_fm=0} NR==1 && $0=="---"{in_fm=1; next} in_fm && $0=="---"{exit} in_fm && $1=="status"{print $2; exit}' "${marker}")"
  [ "${status}" = "done" ] || continue
  decision="$(awk -F': *' 'BEGIN{in_fm=0} NR==1 && $0=="---"{in_fm=1; next} in_fm && $0=="---"{exit} in_fm && $1=="release_note"{print $2; exit}' "${marker}")"
  [ "${decision}" != "no-release-note" ] || continue
  awk '
    /^# Release Notes$/ { in_notes=1; found=1; next }
    found && /^# / { exit }
    in_notes { print }
  ' "${marker}" | sed '/^[[:space:]]*$/d' >>"${tmp}"
done

if [ ! -s "${tmp}" ]; then
  rm -f "${tmp}"
  echo "collect-taskr-release-notes.sh: no release notes found" >&2
  exit 1
fi

sed 's/^/- /' "${tmp}"
rm -f "${tmp}"
