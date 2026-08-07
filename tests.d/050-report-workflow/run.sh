#!/usr/bin/env bash
set -euo pipefail

# Derive shared fixture paths from Smokey state for this runner.
TASKR_BIN="${TASKR_BIN:-taskr}"
TASKR_BASE_ROOT="${TASKR_BASE_ROOT:-${SMOKEY_STATE_DIR}/fixtures/base-root}"

# Run a command and capture its outputs for assertions.
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

# Copy a valid root for report generation.
root="${SMOKEY_STATE_DIR}/report-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"

# Reports should render deterministic stdout for parent and status filters.
run_taskr report_under "${root}" report --under 001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "report root=" "${stdout}"
grep -q "under=001" "${stdout}"
run_taskr report_done "${root}" report --under 001 --type task --status done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "report root=" "${stdout}"
grep -q "type=task" "${stdout}"
grep -q "status=done" "${stdout}"
grep -q "002 done Define directory structure" "${stdout}"

# File reports should write the target and report the written path.
target="${SMOKEY_STATE_DIR}/done.txt"
run_taskr report_file "${root}" report --under 001 --type task --status done --output "${target}"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "wrote report path=${target}" "${stdout}"
grep -q "002 done Define directory structure" "${target}"

# Invalid report inputs should fail clearly.
run_taskr report_missing "${root}" report --under missing
[ "${exit_code}" -ne 0 ] || { echo "missing report parent should fail" >&2; exit 1; }
grep -qi "not found\\|no match" "${stderr}"
run_taskr report_bad_status "${root}" report --status nonsense
[ "${exit_code}" -ne 0 ] || { echo "unknown report status should fail" >&2; exit 1; }
grep -qi "status\\|unknown\\|invalid" "${stderr}"
run_taskr report_bad_output "${root}" report --output /not-writable/report.txt
[ "${exit_code}" -ne 0 ] || { echo "unwritable report target should fail" >&2; exit 1; }
grep -qi "write\\|permission\\|output" "${stderr}"
