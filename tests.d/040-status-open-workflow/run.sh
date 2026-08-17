#!/usr/bin/env bash
set -euo pipefail


# A real status transition must timestamp both the target status and the marker update.
assert_status_timestamp() {
  local marker="$1"
  local field="$2"
  local transition_at
  local updated_at
  transition_at="$(sed -n "s/^${field}: //p" "${marker}")"
  updated_at="$(sed -n 's/^updated_at: //p' "${marker}")"
  if ! [[ "${transition_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    echo "missing or invalid ${field} in ${marker}: ${transition_at:-<missing>}" >&2
    return 1
  fi
  if [ "${updated_at}" != "${transition_at}" ]; then
    echo "updated_at does not match ${field} in ${marker}: ${updated_at} != ${transition_at}" >&2
    return 1
  fi
}

# Metadata output must expose every transition timestamp stored in the marker.
assert_show_timestamp() {
  local output="$1"
  local label="$2"
  if ! grep -Eq "^${label}: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$" "${output}"; then
    echo "show --meta is missing ${label}" >&2
    return 1
  fi
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
grep -q "004 subtask developing #copy Define selectors" "${stdout}"
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
grep -q "004 subtask reviewing #copy Define selectors" "${stdout}"
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

run_taskr show_child_transition_meta "${root}" show 004 --meta
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_show_timestamp "${stdout}" "Developing at"
assert_show_timestamp "${stdout}" "Reviewing at"
assert_show_timestamp "${stdout}" "Done at"

# Remaining target statuses should each record their latest transition time.
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

# Re-entering active replaces its previous timestamp with the latest entry.
sed -i 's/^active_at: .*/active_at: 2020-01-01T00:00:00Z/' "${open_task_marker}"
# The fixture predates transition metadata, so add a valid previous entry.
if ! grep -q '^active_at:' "${open_task_marker}"; then
  sed -i '/^updated_at:/a active_at: 2020-01-01T00:00:00Z' "${open_task_marker}"
fi
run_taskr status_task_active_again "${root}" status 005 active
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_status_timestamp "${open_task_marker}" active_at
if grep -q '^active_at: 2020-01-01T00:00:00Z$' "${open_task_marker}"; then
  echo "re-entering active should replace active_at" >&2
  exit 1
fi

# Repeating the current status is a successful no-op with no marker rewrite.
marker_before_noop="$(sha256sum "${open_task_marker}")"
run_taskr status_task_active_noop "${root}" status 005 active
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'changed=false' "${stdout}"
[ "$(sha256sum "${open_task_marker}")" = "${marker_before_noop}" ]

run_taskr show_task_transition_meta "${root}" show 005 --meta
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
assert_show_timestamp "${stdout}" "Open at"
assert_show_timestamp "${stdout}" "Designing at"
assert_show_timestamp "${stdout}" "Active at"
assert_show_timestamp "${stdout}" "Blocked at"
assert_show_timestamp "${stdout}" "Cancelled at"
assert_show_timestamp "${stdout}" "Reopened at"

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

# Doctor accepts missing transition history but rejects malformed timestamps.
run_taskr doctor_optional_timestamps "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
invalid_timestamp_root="${SMOKEY_STATE_DIR}/status-invalid-timestamp-root"
cp -R "${root}" "${invalid_timestamp_root}"
sed -i 's/^active_at: .*/active_at: not-a-timestamp/' "${invalid_timestamp_root}/001-mvp/005-open-work/task.md"
run_taskr doctor_invalid_timestamp "${invalid_timestamp_root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "doctor should reject an invalid transition timestamp" >&2; exit 1; }
grep -qi 'active_at.*timestamp' "${stderr}"
