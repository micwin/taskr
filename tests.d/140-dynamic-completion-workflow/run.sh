#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
TASKR_BASE_ROOT="${TASKR_BASE_ROOT:-${SMOKEY_STATE_DIR}/fixtures/base-root}"

run_complete() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  "${TASKR_BIN}" "$@" >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
}

assert_selector_completion() {
  local name="$1"
  shift
  run_complete "${name}" "${root}" __complete "$@"
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  grep -qx $'001\tmilestone active MVP' "${stdout}"
  grep -qx $'mvp\tmilestone active MVP' "${stdout}"
  grep -qx $'002\ttask done Define directory structure' "${stdout}"
  grep -qx $'verzeichnisstruktur\ttask done Define directory structure' "${stdout}"
  grep -qx $'003\ttask active Define workflows' "${stdout}"
  grep -qx $'workflows-definieren\ttask active Define workflows' "${stdout}"
  grep -qx $'004\tsubtask designing Define selectors' "${stdout}"
  grep -qx $'define-selectors\tsubtask designing Define selectors' "${stdout}"
}

assert_tree_root_completion() {
  local name="$1"
  shift
  run_complete "${name}" "${root}" __complete "$@"
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  grep -qx $'001\tmilestone active MVP' "${stdout}"
  grep -qx $'mvp\tmilestone active MVP' "${stdout}"
  grep -qx $'003\ttask active Define workflows' "${stdout}"
  grep -qx $'workflows-definieren\ttask active Define workflows' "${stdout}"
  if grep -qx $'002\ttask done Define directory structure' "${stdout}" ||
    grep -qx $'verzeichnisstruktur\ttask done Define directory structure' "${stdout}" ||
    grep -qx $'004\tsubtask designing Define selectors' "${stdout}" ||
    grep -qx $'define-selectors\tsubtask designing Define selectors' "${stdout}"; then
    echo "tree-root completion should hide leaf tasks and subtasks" >&2
    exit 1
  fi
}

assert_write_parent_completion() {
  local name="$1"
  shift
  run_complete "${name}" "${root}" __complete "$@"
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  grep -qx $'001\tmilestone active MVP' "${stdout}"
  grep -qx $'mvp\tmilestone active MVP' "${stdout}"
  grep -qx $'002\ttask done Define directory structure' "${stdout}"
  grep -qx $'verzeichnisstruktur\ttask done Define directory structure' "${stdout}"
  grep -qx $'003\ttask active Define workflows' "${stdout}"
  grep -qx $'workflows-definieren\ttask active Define workflows' "${stdout}"
  if grep -qx $'004\tsubtask designing Define selectors' "${stdout}" ||
    grep -qx $'define-selectors\tsubtask designing Define selectors' "${stdout}"; then
    echo "write-parent completion should hide subtasks" >&2
    exit 1
  fi
}

assert_move_task_parent_completion() {
  local name="$1"
  shift
  run_complete "${name}" "${root}" __complete "$@"
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  grep -qx $'001\tmilestone active MVP' "${stdout}"
  grep -qx $'mvp\tmilestone active MVP' "${stdout}"
  if grep -qx $'002\ttask done Define directory structure' "${stdout}" ||
    grep -qx $'003\ttask active Define workflows' "${stdout}" ||
    grep -qx $'004\tsubtask designing Define selectors' "${stdout}"; then
    echo "move task parent completion should show milestones only" >&2
    exit 1
  fi
}

assert_move_subtask_parent_completion() {
  local name="$1"
  shift
  run_complete "${name}" "${root}" __complete "$@"
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  grep -qx $'002\ttask done Define directory structure' "${stdout}"
  grep -qx $'verzeichnisstruktur\ttask done Define directory structure' "${stdout}"
  grep -qx $'003\ttask active Define workflows' "${stdout}"
  grep -qx $'workflows-definieren\ttask active Define workflows' "${stdout}"
  if grep -qx $'001\tmilestone active MVP' "${stdout}" ||
    grep -qx $'004\tsubtask designing Define selectors' "${stdout}"; then
    echo "move subtask parent completion should show tasks only" >&2
    exit 1
  fi
}

assert_move_source_completion() {
  local name="$1"
  shift
  run_complete "${name}" "${root}" __complete "$@"
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  grep -qx $'002\ttask done Define directory structure' "${stdout}"
  grep -qx $'verzeichnisstruktur\ttask done Define directory structure' "${stdout}"
  grep -qx $'003\ttask active Define workflows' "${stdout}"
  grep -qx $'workflows-definieren\ttask active Define workflows' "${stdout}"
  grep -qx $'004\tsubtask designing Define selectors' "${stdout}"
  grep -qx $'define-selectors\tsubtask designing Define selectors' "${stdout}"
  if grep -qx $'001\tmilestone active MVP' "${stdout}" ||
    grep -qx $'mvp\tmilestone active MVP' "${stdout}"; then
    echo "move source completion should hide milestones" >&2
    exit 1
  fi
}

assert_rootless_selector_completion() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  (
    cd "${root}"
    "${TASKR_BIN}" __complete "$@"
  ) >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  grep -qx $'001\tmilestone active MVP' "${stdout}"
  grep -qx $'mvp\tmilestone active MVP' "${stdout}"
  grep -qx $'003\ttask active Define workflows' "${stdout}"
  grep -qx $'workflows-definieren\ttask active Define workflows' "${stdout}"
  if grep -qx $'002\ttask done Define directory structure' "${stdout}" ||
    grep -qx $'004\tsubtask designing Define selectors' "${stdout}"; then
    echo "rootless tree completion should hide leaf tasks and subtasks" >&2
    exit 1
  fi
}

root="${SMOKEY_STATE_DIR}/completion-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"

# Item type completion should work for positional and flag values.
run_complete create_type "${root}" __complete create ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx "milestone" "${stdout}"
grep -qx "task" "${stdout}"
grep -qx "subtask" "${stdout}"

run_complete list_type_flag "${root}" __complete list --type ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx "milestone" "${stdout}"
grep -qx "task" "${stdout}"
grep -qx "subtask" "${stdout}"

# Status completion should work for flags and status command arguments.
run_complete list_status_flag "${root}" __complete list --status ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx "open" "${stdout}"
grep -qx "designing" "${stdout}"
grep -qx "developing" "${stdout}"
grep -qx "active" "${stdout}"
grep -qx "reviewing" "${stdout}"
grep -qx "blocked" "${stdout}"
grep -qx "done" "${stdout}"
grep -qx "cancelled" "${stdout}"

run_complete status_value_arg "${root}" __complete status 003 ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx "developing" "${stdout}"
grep -qx "reviewing" "${stdout}"
grep -qx "done" "${stdout}"
grep -qx "cancelled" "${stdout}"

# Direct selector completion should include IDs and slugs for every item.
assert_selector_completion comment_selector comment ""
assert_selector_completion show_selector show ""
assert_selector_completion status_selector status ""
assert_selector_completion open_selector open ""
assert_selector_completion archive_selector archive ""

# Move sources should complete movable items only: tasks and subtasks, but not
# milestones.
assert_move_source_completion move_selector move ""

# Tree and read-only parent filters should complete useful tree roots only:
# milestones and tasks with subtasks, but no leaf tasks or subtasks.
assert_tree_root_completion tree_selector tree ""
assert_tree_root_completion list_under list --under ""

# Write parent selectors should complete possible parent items: milestones and
# tasks, including leaf tasks for new subtasks, but no subtasks.
assert_write_parent_completion create_under create subtask "New work" --under ""
assert_move_task_parent_completion move_task_under move 003 --under ""
assert_move_subtask_parent_completion move_subtask_under move 004 --under ""

# Shell completion calls hidden Cobra completion commands without an explicit
# Taskr root argument, so root discovery must still work from the current dir.
assert_rootless_selector_completion tree_rootless_selector tree ""

# Missing roots should not leak normal command errors into completion.
run_complete missing_root "${SMOKEY_STATE_DIR}/missing-completion-root" __complete show ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
if grep -qi "root not found\\|no such\\|invalid marker" "${stdout}" "${stderr}"; then
  echo "completion should suppress normal root errors" >&2
  exit 1
fi
