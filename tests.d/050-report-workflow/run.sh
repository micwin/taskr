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
run_taskr report_create_empty_milestone "${root}" create milestone "Future Work" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr report_mark_developing "${root}" status 003 developing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr report_mark_reviewing "${root}" status 005 reviewing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
for title in "Current One" "Current Two" "Current Three" "Current Four" "Current Five" "Current Six"; do
  run_taskr "report_create_${title// /_}" "${root}" create task "${title}" --under 001 --no-edit
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
done
for id in 007 008 009 010 011 012; do
  run_taskr "report_develop_${id}" "${root}" status "${id}" developing
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
done

# Default reports should render repository-level summary data from the fixture.
run_taskr report_default "${root}" report
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "^Taskr report$" "${stdout}"
grep -q "^Project: report-root$" "${stdout}"
grep -Eq "^Report date: [0-9]{4}-[0-9]{2}-[0-9]{2}$" "${stdout}"
grep -q "^# Status Summary$" "${stdout}"
grep -q '^milestones with status "open": 1$' "${stdout}"
grep -q '^milestones with status "active": 1$' "${stdout}"
grep -q '^tasks with status "developing": 7$' "${stdout}"
grep -q '^tasks with status "reviewing": 1$' "${stdout}"
grep -q '^tasks with status "done": 1$' "${stdout}"
grep -q '^subtasks with status "designing": 1$' "${stdout}"
grep -q "^# Status Extremes$" "${stdout}"
grep -q "^## Milestones$" "${stdout}"
grep -q "^Oldest open: 006 \\[open\\] Future Work$" "${stdout}"
grep -q "^## Tasks$" "${stdout}"
grep -q "^Oldest developing: 003 \\[developing\\] Define workflows$" "${stdout}"
grep -q "^Newest done: 002 \\[done\\] Define directory structure$" "${stdout}"
grep -q "^## Subtasks$" "${stdout}"
grep -q "^Oldest designing: 004 \\[designing\\] Define selectors$" "${stdout}"
grep -q "^# Milestones$" "${stdout}"
grep -q "^## MVP (mvp) \\[active\\]$" "${stdout}"
grep -q "^### Ticket Status Counts$" "${stdout}"
grep -q '^tasks with status "developing": 7$' "${stdout}"
grep -q '^tasks with status "reviewing": 1$' "${stdout}"
grep -q '^tasks with status "done": 1$' "${stdout}"
grep -q "^### Current 5 developing/reviewing tasks (showing 5 of 8)$" "${stdout}"
grep -q "^003 \\[developing\\] Define workflows$" "${stdout}"
grep -q "^005 \\[reviewing\\] Open work$" "${stdout}"
grep -q "^009 \\[developing\\] Current Three$" "${stdout}"
if grep -q "^010 \\[developing\\] Current Four$" "${stdout}"; then
  echo "default report should show a truncation heading instead of every current ticket" >&2
  exit 1
fi
grep -q "^# Open Milestones Without Tickets$" "${stdout}"
grep -q "^006 \\[open\\] Future Work$" "${stdout}"
if grep -q "^# Matching Items$" "${stdout}"; then
  echo "default report should not include an unstructured matching-items list" >&2
  exit 1
fi

# File reports should write the top-level report and report the written path.
target="${SMOKEY_STATE_DIR}/done.txt"
run_taskr report_file "${root}" report --output "${target}"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "wrote report path=${target}" "${stdout}"
grep -q "^Taskr report$" "${target}"
grep -q "^# Open Milestones Without Tickets$" "${target}"

# Invalid report inputs should fail clearly.
run_taskr report_reject_under "${root}" report --under 001
[ "${exit_code}" -ne 0 ] || { echo "report should not accept parent filters yet" >&2; exit 1; }
grep -qi "unknown flag.*under" "${stderr}"
run_taskr report_reject_status "${root}" report --status done
[ "${exit_code}" -ne 0 ] || { echo "report should not accept status filters yet" >&2; exit 1; }
grep -qi "unknown flag.*status" "${stderr}"
run_taskr report_bad_output "${root}" report --output /not-writable/report.txt
[ "${exit_code}" -ne 0 ] || { echo "unwritable report target should fail" >&2; exit 1; }
grep -qi "write\\|permission\\|output" "${stderr}"
