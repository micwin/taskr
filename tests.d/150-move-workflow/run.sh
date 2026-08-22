#!/usr/bin/env bash
set -euo pipefail


root="${SMOKEY_STATE_DIR}/move-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"

# Create a second milestone as destination for task moves.
run_taskr create_release "${root}" create milestone "Release" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "created item id=006" "${stdout}"

# Move a task from MVP to Release.
run_taskr move_under "${root}" move 002 --under 006
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "moved id=002" "${stdout}"
grep -q "type=task" "${stdout}"
grep -q "from=001-mvp/002-verzeichnisstruktur" "${stdout}"
grep -q "to=006-release/002-verzeichnisstruktur" "${stdout}"
test -f "${root}/006-release/002-verzeichnisstruktur/task.md"
test ! -e "${root}/001-mvp/002-verzeichnisstruktur"

# The moved item should remain visible and doctor-clean.
run_taskr show_moved "${root}" show 002
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "^Marker: 006-release/002-verzeichnisstruktur/task.md$" "${stdout}"

run_taskr doctor_after_move "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "ok root=" "${stdout}"

# Move the task back to the root level.
run_taskr move_root "${root}" move 002 --root
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "moved id=002" "${stdout}"
grep -q "to=002-verzeichnisstruktur" "${stdout}"
test -f "${root}/002-verzeichnisstruktur/task.md"

# Invalid move modes should fail clearly.
run_taskr move_missing_mode "${root}" move 002
[ "${exit_code}" -ne 0 ] || { echo "move without destination should fail" >&2; exit 1; }
grep -qi "under\\|root\\|destination" "${stderr}"

run_taskr move_two_modes "${root}" move 002 --under 001 --root
[ "${exit_code}" -ne 0 ] || { echo "move with two destinations should fail" >&2; exit 1; }
grep -qi "under\\|root\\|exclusive" "${stderr}"

run_taskr move_missing_source "${root}" move missing --under 001
[ "${exit_code}" -ne 0 ] || { echo "move missing source should fail" >&2; exit 1; }
grep -qi "not found\\|no match" "${stderr}"

run_taskr move_missing_parent "${root}" move 002 --under missing
[ "${exit_code}" -ne 0 ] || { echo "move missing parent should fail" >&2; exit 1; }
grep -qi "not found\\|no match" "${stderr}"

run_taskr move_task_under_task "${root}" move 005 --under 003
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "moved id=005" "${stdout}"
grep -q "type=task->subtask" "${stdout}"
grep -q "to=001-mvp/003-workflows-definieren/005-open-work" "${stdout}"
test -f "${root}/001-mvp/003-workflows-definieren/005-open-work/subtask.md"
test ! -e "${root}/001-mvp/005-open-work"

run_taskr move_subtask_to_milestone "${root}" move 005 --under 006
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "moved id=005" "${stdout}"
grep -q "type=subtask->task" "${stdout}"
grep -q "to=006-release/005-open-work" "${stdout}"
test -f "${root}/006-release/005-open-work/task.md"
test ! -e "${root}/001-mvp/003-workflows-definieren/005-open-work"

run_taskr show_retyped "${root}" show 005 --meta
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "^Type: task$" "${stdout}"
grep -q "^Marker: 006-release/005-open-work/task.md$" "${stdout}"

run_taskr move_subtask_under_milestone "${root}" move 004 --under 001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "moved id=004" "${stdout}"
grep -q "type=subtask->task" "${stdout}"
test -f "${root}/001-mvp/004-define-selectors/task.md"

closed_parent_root="${SMOKEY_STATE_DIR}/move-closed-parent-root"
cp -R "${TASKR_BASE_ROOT}" "${closed_parent_root}"
run_taskr move_close_child "${closed_parent_root}" status 004 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr move_close_parent "${closed_parent_root}" status 003 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr move_open_under_done_task "${closed_parent_root}" move 005 --under 003
[ "${exit_code}" -ne 0 ] || { echo "open task should not move under done task" >&2; exit 1; }
grep -qi "closed\\|terminal\\|done\\|parent" "${stderr}"

rollback_root="${SMOKEY_STATE_DIR}/move-rollback-root"
cp -R "${TASKR_BASE_ROOT}" "${rollback_root}"
run_taskr move_invalid_retype_with_children "${rollback_root}" move 003 --under 005
[ "${exit_code}" -ne 0 ] || { echo "task with subtask should not retype below task when invalid" >&2; exit 1; }
grep -qi "invalid\\|cannot\\|subtask\\|children" "${stderr}"
test -f "${rollback_root}/001-mvp/003-workflows-definieren/task.md"
test -f "${rollback_root}/001-mvp/003-workflows-definieren/004-define-selectors/subtask.md"

run_taskr move_into_self "${root}" move 001 --under 001
[ "${exit_code}" -ne 0 ] || { echo "move into self should fail" >&2; exit 1; }
grep -qi "self\\|descendant" "${stderr}"

# Help and completion surfaces should expose move.
run_taskr move_help "${root}" move --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "taskr move <selector>" "${stdout}"
grep -q -- "--under" "${stdout}"
grep -q -- "--root" "${stdout}"
grep -qi "type\\|retype\\|converted\\|automatic" "${stdout}"
grep -qi "closed\\|terminal\\|done\\|cancelled" "${stdout}"

run_taskr move_completion "${root}" __complete move ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'003\ttask active Define workflows' "${stdout}"
grep -qx $'004\ttask designing Define selectors' "${stdout}"
if grep -qx $'001\tmilestone active MVP' "${stdout}"; then
  echo "move source completion should hide milestones" >&2
  exit 1
fi
