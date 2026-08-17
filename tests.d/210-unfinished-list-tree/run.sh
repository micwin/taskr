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

# Build one valid root containing every lifecycle status and item type.
root="${SMOKEY_STATE_DIR}/unfinished-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
run_taskr create_open "${root}" create task "Open task" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_developing "${root}" create task "Developing task" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr status_developing "${root}" status 007 developing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_reviewing "${root}" create task "Reviewing task" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr status_reviewing "${root}" status 008 reviewing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_blocked "${root}" create task "Blocked task" --under 001 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr status_blocked "${root}" status 009 blocked
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr status_cancelled "${root}" status 005 cancelled
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_done_subtask "${root}" create subtask "Done subtask" --under 003 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr status_done_subtask "${root}" status 010 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_cancelled_subtask "${root}" create subtask "Cancelled subtask" --under 003 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr status_cancelled_subtask "${root}" status 011 cancelled
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_done_milestone "${root}" create milestone "Done milestone" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr status_done_milestone "${root}" status 012 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_cancelled_milestone "${root}" create milestone "Cancelled milestone" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr status_cancelled_milestone "${root}" status 013 cancelled
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Default list should include every non-terminal status and exclude both terminal statuses.
run_taskr list_unfinished "${root}" list
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '001 milestone active #(public,website) MVP' "${stdout}"
grep -q '003 task active #(release,website) Define workflows' "${stdout}"
grep -q '004 subtask designing #copy Define selectors' "${stdout}"
grep -q '006 task open Open task' "${stdout}"
grep -q '007 task developing Developing task' "${stdout}"
grep -q '008 task reviewing Reviewing task' "${stdout}"
grep -q '009 task blocked Blocked task' "${stdout}"
if grep -q ' done \| cancelled ' "${stdout}"; then
  echo "default list should exclude done and cancelled items" >&2
  exit 1
fi

# List --all should restore terminal milestones, tasks, and subtasks.
run_taskr list_all "${root}" list --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '002 task done #internal Define directory structure' "${stdout}"
grep -q '005 task cancelled Open work' "${stdout}"
grep -q '010 subtask done Done subtask' "${stdout}"
grep -q '011 subtask cancelled Cancelled subtask' "${stdout}"
grep -q '012 milestone done Done milestone' "${stdout}"
grep -q '013 milestone cancelled Cancelled milestone' "${stdout}"

# Terminal status filters should require --all while non-terminal filters remain direct.
run_taskr list_done_without_all "${root}" list --status done
[ "${exit_code}" -eq 2 ] || { echo "terminal list status without --all should exit 2" >&2; exit 1; }
grep -qi 'done.*--all\|--all.*done' "${stderr}"
run_taskr list_cancelled_without_all "${root}" list --status cancelled
[ "${exit_code}" -eq 2 ] || { echo "cancelled list status without --all should exit 2" >&2; exit 1; }
grep -qi 'cancelled.*--all\|--all.*cancelled' "${stderr}"
run_taskr list_done_with_all "${root}" list --all --status done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '002 task done #internal Define directory structure' "${stdout}"
grep -q '010 subtask done Done subtask' "${stdout}"
grep -q '012 milestone done Done milestone' "${stdout}"
if grep -q ' cancelled ' "${stdout}"; then
  echo "done status filter should exclude cancelled items" >&2
  exit 1
fi
run_taskr list_reviewing "${root}" list --status reviewing
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^008 task reviewing Reviewing task$' "${stdout}"

# --all should compose with parent, type, priority, grouping, and display filters.
run_taskr priority_done "${root}" priority 002 high
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr priority_open "${root}" priority 006 high
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr list_priority_default "${root}" list --under 001 --type task --priority high --show-priority
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^006 task open priority=high Open task$' "${stdout}"
if grep -q '^002 ' "${stdout}"; then
  echo "priority filter should not bypass default terminal filtering" >&2
  exit 1
fi
run_taskr list_priority_all "${root}" list --all --under 001 --type task --priority high --group-by priority
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Priority: high$' "${stdout}"
grep -q '^  002 task done #internal Define directory structure$' "${stdout}"
grep -q '^  006 task open Open task$' "${stdout}"

# Tree should use the same default and --all visibility for every item type.
run_taskr tree_unfinished "${root}" tree
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '007 \[task developing\] Developing task' "${stdout}"
grep -q '008 \[task reviewing\] Reviewing task' "${stdout}"
if grep -q ' done\]\| cancelled\]' "${stdout}"; then
  echo "default tree should exclude done and cancelled items" >&2
  exit 1
fi
run_taskr tree_all "${root}" tree --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '002 \[task done priority=high\] #internal Define directory structure' "${stdout}"
grep -q '005 \[task cancelled\] Open work' "${stdout}"
grep -q '010 \[subtask done\] Done subtask' "${stdout}"
grep -q '011 \[subtask cancelled\] Cancelled subtask' "${stdout}"
grep -q '012 \[milestone done\] Done milestone' "${stdout}"
grep -q '013 \[milestone cancelled\] Cancelled milestone' "${stdout}"

# Help, examples, and completion should expose --all and remove tree --open.
run_taskr list_help "${root}" list --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qi 'default.*done.*cancelled\|done.*cancelled.*default' "${stdout}"
grep -q -- '--all' "${stdout}"
run_taskr tree_help "${root}" tree --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- '--all' "${stdout}"
if grep -q -- '--open' "${stdout}"; then
  echo "tree help should not expose removed --open" >&2
  exit 1
fi
run_taskr list_flag_completion "${root}" __complete list --
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^--all' "${stdout}"
run_taskr tree_flag_completion "${root}" __complete tree --
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^--all' "${stdout}"
if grep -q '^--open' "${stdout}"; then
  echo "tree completion should not expose removed --open" >&2
  exit 1
fi
run_taskr unfinished_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^  taskr list$' "${stdout}"
grep -q 'taskr list --all --type task --status done --under 001' "${stdout}"
grep -q 'taskr tree 001 --all' "${stdout}"
if grep -q 'taskr tree .*--open' "${stdout}"; then
  echo "examples should not expose removed tree --open" >&2
  exit 1
fi
