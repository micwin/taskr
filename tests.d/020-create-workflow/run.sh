#!/usr/bin/env bash
set -euo pipefail

# Create a complete hierarchy from an empty root with editor disabled.
root="${SMOKEY_STATE_DIR}/create-root"
mkdir -p "${root}"
run_taskr create_milestone "${root}" create milestone "MVP" --no-edit
if [ "${exit_code}" -ne 0 ]; then
  echo "milestone creation should pass" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q "created item id=001" "${stdout}"
grep -q "marker=milestone.md" "${stdout}"
grep -q "opened=false" "${stdout}"

# Create tasks and a subtask under the generated hierarchy.
run_taskr create_structure "${root}" create task "Define directory structure" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "created item id=002" "${stdout}"
grep -q "marker=task.md" "${stdout}"
run_taskr create_workflows "${root}" create task "Define workflows" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "created item id=003" "${stdout}"
run_taskr create_selectors "${root}" create subtask "Define selectors" --under 003 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "created item id=004" "${stdout}"
grep -q "marker=subtask.md" "${stdout}"

# Editor mode should launch the configured editor and still report the created item.
EDITOR=true run_taskr create_with_editor "${root}" create task "Open in editor" --under 001 --edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "opened=true" "${stdout}"

# Invalid create operations should fail with specific user-facing reasons.
run_taskr create_no_parent "${root}" create task "No parent"
[ "${exit_code}" -ne 0 ] || { echo "task without parent should fail" >&2; exit 1; }
grep -qi "parent\\|under" "${stderr}"
run_taskr create_bad_child "${root}" create subtask "Define Rubbish" --under 001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "subtask under milestone should fail" >&2; exit 1; }
grep -qi "cannot create\\|not allowed\\|milestone" "${stderr}"
run_taskr create_duplicate_slug "${root}" create milestone "Duplicate" --slug mvp
[ "${exit_code}" -ne 0 ] || { echo "duplicate milestone slug should fail" >&2; exit 1; }
grep -qi "duplicate\\|exists\\|slug" "${stderr}"

# New work must not be added below terminal parent context.
closed_root="${SMOKEY_STATE_DIR}/create-closed-parent-root"
mkdir -p "${closed_root}"
run_taskr closed_create_milestone "${closed_root}" create milestone "Closed Context" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr closed_mark_milestone_done "${closed_root}" status 001 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_under_done_milestone "${closed_root}" create task "Too late" --under 001 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "task under done milestone should fail" >&2; exit 1; }
grep -qi "closed\\|terminal\\|done\\|parent" "${stderr}"

run_taskr reopened_milestone "${closed_root}" status 001 open
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_closeable_task "${closed_root}" create task "Closeable task" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr closed_mark_task_done "${closed_root}" status 002 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_under_done_task "${closed_root}" create subtask "Too late subtask" --under 002 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "subtask under done task should fail" >&2; exit 1; }
grep -qi "closed\\|terminal\\|done\\|parent" "${stderr}"

# A subtask create must also reject a closed milestone ancestor, even when the
# immediate task marker is still open due to externally corrupted data.
ancestor_root="${SMOKEY_STATE_DIR}/create-closed-ancestor-root"
cp -R "${TASKR_BASE_ROOT}" "${ancestor_root}"
sed -i 's/^status: active$/status: done/' "${ancestor_root}/001-mvp/milestone.md"
run_taskr create_under_done_milestone_ancestor "${ancestor_root}" create subtask "Too late nested" --under 003 --no-edit
[ "${exit_code}" -ne 0 ] || { echo "subtask under done milestone ancestor should fail" >&2; exit 1; }
grep -qi "closed\\|terminal\\|done\\|milestone\\|ancestor" "${stderr}"
