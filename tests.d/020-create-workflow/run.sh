#!/usr/bin/env bash
set -euo pipefail

# Derive shared executable path from Smokey state for this runner.
TASKR_BIN="${TASKR_BIN:-taskr}"

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
