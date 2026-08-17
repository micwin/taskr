#!/usr/bin/env bash
set -euo pipefail


# Valid roots should pass doctor with a deterministic summary.
root="${SMOKEY_STATE_DIR}/doctor-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
run_taskr doctor_valid "${root}" doctor
if [ "${exit_code}" -ne 0 ]; then
  echo "doctor should pass for valid root" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q "ok root=" "${stdout}"
grep -q "items=" "${stdout}"
grep -q "files=" "${stdout}"

# Missing roots should fail clearly.
run_taskr doctor_missing "${SMOKEY_STATE_DIR}/missing-root" doctor
if [ "${exit_code}" -eq 0 ]; then
  echo "doctor should fail for missing root" >&2
  exit 1
fi
grep -qi "not found\\|missing\\|no such" "${stderr}"

# Invalid marker structure should fail with the invalid path.
run_taskr doctor_invalid "${TASKR_INVALID_ROOT}" doctor
if [ "${exit_code}" -eq 0 ]; then
  echo "doctor should fail for invalid marker structure" >&2
  exit 1
fi
grep -q "001-broken" "${stderr}"

# Terminal parents must not contain unfinished descendants.
terminal_parent_root="${SMOKEY_STATE_DIR}/doctor-terminal-parent-root"
cp -R "${TASKR_BASE_ROOT}" "${terminal_parent_root}"
sed -i 's/^status: active$/status: done/' "${terminal_parent_root}/001-mvp/003-workflows-definieren/task.md"
run_taskr doctor_terminal_parent_child "${terminal_parent_root}" doctor
if [ "${exit_code}" -eq 0 ]; then
  echo "doctor should fail when a done task contains an unfinished subtask" >&2
  exit 1
fi
grep -qi "003\\|004" "${stderr}"
grep -qi "unfinished\\|terminal\\|done\\|closed" "${stderr}"

# Normal loaded-worktree commands should reject the same invalid state.
run_taskr startup_terminal_parent_child "${terminal_parent_root}" list
if [ "${exit_code}" -eq 0 ]; then
  echo "list should fail when a done task contains an unfinished subtask" >&2
  exit 1
fi
grep -qi "003\\|004" "${stderr}"
grep -qi "unfinished\\|terminal\\|done\\|closed" "${stderr}"

# Closed milestone ancestry also invalidates unfinished descendant work.
terminal_milestone_root="${SMOKEY_STATE_DIR}/doctor-terminal-milestone-root"
cp -R "${TASKR_BASE_ROOT}" "${terminal_milestone_root}"
sed -i 's/^status: active$/status: cancelled/' "${terminal_milestone_root}/001-mvp/milestone.md"
run_taskr doctor_terminal_milestone_child "${terminal_milestone_root}" doctor
if [ "${exit_code}" -eq 0 ]; then
  echo "doctor should fail when a cancelled milestone contains unfinished descendants" >&2
  exit 1
fi
grep -qi "001\\|003\\|004\\|005" "${stderr}"
grep -qi "unfinished\\|terminal\\|cancelled\\|closed" "${stderr}"
