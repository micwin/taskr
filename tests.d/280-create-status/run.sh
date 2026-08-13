#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
TASKR_BASE_ROOT="${TASKR_BASE_ROOT:-${SMOKEY_STATE_DIR}/fixtures/base-root}"

run_taskr() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  "${TASKR_BIN}" "$@" >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
}

marker_field() {
  local marker="$1"
  local field="$2"
  sed -n "s/^${field}: //p" "${marker}"
}

assert_creation_timestamps() {
  local marker="$1"
  local status="$2"
  local created updated status_at
  created="$(marker_field "${marker}" created_at)"
  updated="$(marker_field "${marker}" updated_at)"
  status_at="$(marker_field "${marker}" "${status}_at")"
  [[ "${created}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
  [ "${created}" = "${updated}" ]
  [ "${created}" = "${status_at}" ]
}

# Use one valid isolated root for every initial-status creation workflow.
root="${SMOKEY_STATE_DIR}/create-status-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"

# Create defaults to open and records one consistent creation/status timestamp.
run_taskr create_status_default "${root}" create task "Default initial status" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
marker="$(find "${root}" -path '*-default-initial-status/task.md' -print -quit)"
[ -n "${marker}" ]
grep -qx 'status: open' "${marker}"
assert_creation_timestamps "${marker}" open

# Every non-closed built-in status can be selected explicitly.
for status in open designing developing active reviewing blocked; do
  title="Initial ${status} item"
  run_taskr "create_status_${status}" "${root}" create task "${title}" --under 001 --status "${status}" --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  marker="$(find "${root}" -path "*-initial-${status}-item/task.md" -print -quit)"
  [ -n "${marker}" ]
  grep -qx "status: ${status}" "${marker}"
  assert_creation_timestamps "${marker}" "${status}"
done

# Closed and unknown statuses fail before creating a directory.
before="$(find "${root}" -type d | sort | sha256sum)"
for status in done cancelled unknown; do
  run_taskr "create_status_reject_${status}" "${root}" create task "Rejected ${status}" --under 001 --status "${status}" --no-edit
  [ "${exit_code}" -eq 2 ] || { echo "initial status ${status} should exit 2" >&2; exit 1; }
  grep -qi 'invalid.*status\|status.*not.*initial\|closed' "${stderr}"
  [ "${before}" = "$(find "${root}" -type d | sort | sha256sum)" ]
done

# Status composes with slug and editor controls without changing output format.
run_taskr create_status_composed "${root}" create subtask "Verify malformed input" --under 003 --slug verify-input --status developing --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Eq '^created item id=[0-9]+ path=.*verify-input marker=subtask.md opened=false$' "${stdout}"
marker="$(find "${root}" -path '*-verify-input/subtask.md' -print -quit)"
grep -qx 'status: developing' "${marker}"
assert_creation_timestamps "${marker}" developing

# Help documents the default and exact valid initial values.
run_taskr create_status_help create --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- '--status string' "${stdout}"
grep -qi 'default.*open\|open.*default' "${stdout}"
for status in open designing developing active reviewing blocked; do
  grep -qw "${status}" "${stdout}"
done

# Examples include ordinary and composed initial-status workflows.
run_taskr create_status_examples examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fq 'taskr create task "Implement parser" --under 001 --status designing' "${stdout}"
grep -Fq 'taskr create subtask "Verify malformed input" --under 002 --status developing --no-edit' "${stdout}"

# Completion offers only statuses that make sense for newly created work.
run_taskr create_status_completion __complete create task Example --status ''
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
for status in open designing developing active reviewing blocked; do
  grep -qx "${status}" "${stdout}"
done
if grep -qx 'done\|cancelled' "${stdout}"; then
  echo "create status completion must exclude closed statuses" >&2
  exit 1
fi
grep -q ':4$' "${stdout}"
