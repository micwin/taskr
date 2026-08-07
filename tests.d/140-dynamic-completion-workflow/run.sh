#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
TASKR_BASE_ROOT="${TASKR_BASE_ROOT:-${SMOKEY_STATE_DIR}/fixtures/base-root}"

run_complete() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  "${TASKR_BIN}" "$@" >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
}

root="${SMOKEY_STATE_DIR}/completion-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"

# Item type completion should work for positional and flag values.
run_complete create_type "${root}" __complete create ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx "milestone" "${stdout}"
grep -qx "task" "${stdout}"
grep -qx "subtask" "${stdout}"

run_complete list_type_flag "${root}" __complete list --type ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx "milestone" "${stdout}"
grep -qx "task" "${stdout}"
grep -qx "subtask" "${stdout}"

# Status completion should work for flags and status command arguments.
run_complete list_status_flag "${root}" __complete list --status ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx "open" "${stdout}"
grep -qx "designing" "${stdout}"
grep -qx "active" "${stdout}"
grep -qx "blocked" "${stdout}"
grep -qx "done" "${stdout}"
grep -qx "cancelled" "${stdout}"

run_complete status_value_arg "${root}" __complete status 003 ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx "done" "${stdout}"
grep -qx "cancelled" "${stdout}"

# Selector completion should include IDs and slugs with useful display labels.
run_complete show_selector "${root}" __complete show ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'001\tmilestone active MVP' "${stdout}"
grep -qx $'mvp\tmilestone active MVP' "${stdout}"
grep -qx $'003\ttask active Define workflows' "${stdout}"
grep -qx $'workflows-definieren\ttask active Define workflows' "${stdout}"

run_complete under_selector "${root}" __complete create task "New work" --under ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'001\tmilestone active MVP' "${stdout}"

# Missing roots should not leak normal command errors into completion.
run_complete missing_root "${SMOKEY_STATE_DIR}/missing-completion-root" __complete show ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
if grep -qi "root not found\\|no such\\|invalid marker" "${stdout}" "${stderr}"; then
  echo "completion should suppress normal root errors" >&2
  exit 1
fi
