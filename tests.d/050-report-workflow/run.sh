#!/usr/bin/env bash
set -euo pipefail

# Derive shared fixture paths from Smokey state for this runner.
TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
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

# Build a report fixture with developing and reviewing work in the copied root.
run_taskr report_mark_developing "${root}" status 003 developing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr report_mark_reviewing "${root}" status 005 reviewing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Default reports should render repository-level summary data from the fixture.
run_taskr report_default "${root}" report
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "^Taskr report$" "${stdout}"
grep -q "^Project: report-root$" "${stdout}"
grep -Eq "^Report date: [0-9]{4}-[0-9]{2}-[0-9]{2}$" "${stdout}"
grep -q "^Status summary$" "${stdout}"
grep -q "^milestone active 1$" "${stdout}"
grep -q "^task developing 1$" "${stdout}"
grep -q "^task reviewing 1$" "${stdout}"
grep -q "^task done 1$" "${stdout}"
grep -q "^subtask designing 1$" "${stdout}"
grep -q "^Oldest developing: 003 task developing Define workflows$" "${stdout}"
grep -q "^Oldest designing: 004 subtask designing Define selectors$" "${stdout}"
grep -q "^Newest done: 002 task done Define directory structure$" "${stdout}"
grep -q "^## MVP (mvp)$" "${stdout}"
grep -q "^tasks developing 1$" "${stdout}"
grep -q "^tasks reviewing 1$" "${stdout}"
grep -q "^tasks done 1$" "${stdout}"
grep -q "^Developing and reviewing tickets$" "${stdout}"
grep -q "^003 developing Define workflows$" "${stdout}"
grep -q "^005 reviewing Open work$" "${stdout}"

# Filtered reports should keep filter semantics while still using report output.
run_taskr report_under "${root}" report --under 001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "^Taskr report$" "${stdout}"
grep -q "under=001" "${stdout}"
run_taskr report_done "${root}" report --under 001 --type task --status done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "^Taskr report$" "${stdout}"
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
