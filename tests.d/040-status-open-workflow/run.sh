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

# A real status transition must timestamp both the target status and the marker update.
assert_status_timestamp() {
  local marker="$1"
  local field="$2"
  local transition_at
  local updated_at
  transition_at="$(sed -n "s/^${field}: //p" "${marker}")"
  updated_at="$(sed -n 's/^updated_at: //p' "${marker}")"
  [[ "${transition_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
  [ "${updated_at}" = "${transition_at}" ]
}

# Copy a valid root for status and open workflows.
root="${SMOKEY_STATE_DIR}/status-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
child_marker="${root}/001-mvp/003-workflows-definieren/004-define-selectors/subtask.md"
open_task_marker="${root}/001-mvp/005-open-work/task.md"

# Parent work cannot close before unfinished children.
run_taskr status_parent_blocked "${root}" status 003 done
[ "${exit_code}" -ne 0 ] || { echo "parent should not close before child" >&2; exit 1; }
grep -q "004" "${stderr}"

# Developing is an accepted intermediate status and still keeps the parent open.
run_taskr status_child_developing "${root}" status 004 developing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "status id=004" "${stdout}"
grep -q "new=developing" "${stdout}"
assert_status_timestamp "${child_marker}" developing_at
run_taskr list_developing "${root}" list --status developing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "004 subtask developing Define selectors" "${stdout}"
run_taskr status_parent_developing_blocked "${root}" status 003 done
[ "${exit_code}" -ne 0 ] || { echo "parent should not close while child is developing" >&2; exit 1; }
grep -q "004" "${stderr}"

# Reviewing is an accepted intermediate status and still keeps the parent open.
run_taskr status_child_reviewing "${root}" status 004 reviewing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "status id=004" "${stdout}"
grep -q "new=reviewing" "${stdout}"
assert_status_timestamp "${child_marker}" reviewing_at
run_taskr list_reviewing "${root}" list --status reviewing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "004 subtask reviewing Define selectors" "${stdout}"
run_taskr status_parent_still_blocked "${root}" status 003 done
[ "${exit_code}" -ne 0 ] || { echo "parent should not close while child is reviewing" >&2; exit 1; }
grep -q "004" "${stderr}"

# Closing child first should allow the parent to close.
run_taskr status_child_done "${root}" status 004 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "status id=004" "${stdout}"
grep -q "new=done" "${stdout}"
assert_status_timestamp "${child_marker}" done_at
run_taskr status_parent_done "${root}" status 003 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "status id=003" "${stdout}"
grep -q "new=done" "${stdout}"
assert_status_timestamp "${root}/001-mvp/003-workflows-definieren/task.md" done_at

# Remaining target statuses should each record their latest transition time.
run_taskr status_task_active "${root}" status 005 active
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_status_timestamp "${open_task_marker}" active_at

run_taskr status_task_blocked "${root}" status 005 blocked
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_status_timestamp "${open_task_marker}" blocked_at

run_taskr status_task_cancelled "${root}" status 005 cancelled
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_status_timestamp "${open_task_marker}" cancelled_at

run_taskr status_task_reopened "${root}" status 005 open
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_status_timestamp "${open_task_marker}" open_at
assert_status_timestamp "${open_task_marker}" reopened_at

run_taskr status_task_designing "${root}" status 005 designing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_status_timestamp "${open_task_marker}" designing_at

# Milestone and invalid status changes should still be rejected.
run_taskr status_milestone_blocked "${root}" status 001 done
[ "${exit_code}" -ne 0 ] || { echo "milestone should not close with active children" >&2; exit 1; }
grep -qi "unfinished\\|active\\|children" "${stderr}"
run_taskr status_unknown "${root}" status 003 nonsense
[ "${exit_code}" -ne 0 ] || { echo "unknown status should fail" >&2; exit 1; }
grep -qi "status\\|unknown\\|invalid" "${stderr}"

# Opening an item uses the configured editor and reports the marker path.
EDITOR=true run_taskr open_editor "${root}" open 003
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "opened path=001-mvp/003-workflows-definieren/task.md opener=editor" "${stdout}"

# Missing editor and missing selector should be reported.
EDITOR= run_taskr open_no_editor "${root}" open 003
[ "${exit_code}" -ne 0 ] || { echo "open without editor should fail" >&2; exit 1; }
grep -qi "editor\\|opener" "${stderr}"
run_taskr open_missing "${root}" open missing
[ "${exit_code}" -ne 0 ] || { echo "open missing selector should fail" >&2; exit 1; }
grep -qi "not found\\|no match" "${stderr}"
