#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
TASKR_BASE_ROOT="${TASKR_BASE_ROOT:-${SMOKEY_STATE_DIR}/fixtures/base-root}"

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

root="${SMOKEY_STATE_DIR}/tree-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"

# Default tree should show active structure and hide fully done leaves.
run_taskr tree_default "${root}" tree
if [ "${exit_code}" -ne 0 ]; then
  echo "default tree should pass" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q '^001 \[milestone active\] #(public,website) MVP$' "${stdout}"
grep -q '^  003 \[task active\] #(release,website) Define workflows$' "${stdout}"
grep -q '^    004 \[subtask designing\] #copy Define selectors$' "${stdout}"
if grep -q '+- \||  ' "${stdout}"; then
  echo "default tree should not use branch markers" >&2
  exit 1
fi
if grep -q 'Define directory structure' "${stdout}"; then
  echo "default tree should hide done leaf items" >&2
  exit 1
fi

# All mode should include done items explicitly.
run_taskr tree_all "${root}" tree --all
if [ "${exit_code}" -ne 0 ]; then
  echo "tree --all should pass" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q '^  002 \[task done\] #internal Define directory structure$' "${stdout}"
grep -q '^  005 \[task active\] Open work$' "${stdout}"

# ASCII mode should preserve the previous branch-marker output.
run_taskr tree_ascii "${root}" tree --ascii
if [ "${exit_code}" -ne 0 ]; then
  echo "tree --ascii should pass" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q '^+- 003 \[task active\] #(release,website) Define workflows$' "${stdout}"
grep -q '^|  +- 004 \[subtask designing\] #copy Define selectors$' "${stdout}"

# Tabs and wide mode should offer alternate indentation styles.
run_taskr tree_tabs "${root}" tree --tabs
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q $'^\t003 \\[task active\\] #(release,website) Define workflows$' "${stdout}"
grep -q $'^\t\t004 \\[subtask designing\\] #copy Define selectors$' "${stdout}"
run_taskr tree_wide "${root}" tree --wide
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^    003 \[task active\] #(release,website) Define workflows$' "${stdout}"
grep -q '^        004 \[subtask designing\] #copy Define selectors$' "${stdout}"

# Selected subtree output should start at the selected item.
run_taskr tree_subtree "${root}" tree 003
if [ "${exit_code}" -ne 0 ]; then
  echo "selected tree should pass" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q '^003 \[task active\] #(release,website) Define workflows$' "${stdout}"
grep -q '^  004 \[subtask designing\] #copy Define selectors$' "${stdout}"
if grep -q '^001 ' "${stdout}"; then
  echo "selected tree should not include parent item" >&2
  exit 1
fi

# Default mode should hide both terminal statuses while --all restores them.
run_taskr status_cancelled "${root}" status 005 cancelled
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Eq '^cancelled_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' "${root}/001-mvp/005-open-work/task.md"
run_taskr tree_without_terminal "${root}" tree
if [ "${exit_code}" -ne 0 ]; then
  echo "default tree should pass after cancellation" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q '^001 \[milestone active\] #(public,website) MVP$' "${stdout}"
if grep -q '\[task done\]\|\[task cancelled\]' "${stdout}"; then
  echo "default tree should hide terminal items" >&2
  exit 1
fi
run_taskr tree_with_terminal "${root}" tree --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^  002 \[task done\] #internal Define directory structure$' "${stdout}"
grep -q '^  005 \[task cancelled\] Open work$' "${stdout}"

# Refinement-style multi-milestone output should stay readable.
run_taskr create_refinement "${root}" create milestone "Refinement" --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr create_tree_task "${root}" create task "Add tree command" --under 006 --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr tree_refinement "${root}" tree 006
if [ "${exit_code}" -ne 0 ]; then
  echo "refinement tree should pass" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q '^006 \[milestone open\] Refinement$' "${stdout}"
grep -q '^  007 \[task open\] Add tree command$' "${stdout}"

# Help and completion should expose tree selectors and filtering flags.
run_taskr tree_help "${root}" tree --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr tree \[selector\]' "${stdout}"
grep -q -- '--all' "${stdout}"
if grep -q -- '--open' "${stdout}"; then
  echo "tree help should not expose removed --open flag" >&2
  exit 1
fi
grep -q -- '--ascii' "${stdout}"
grep -q -- '--tabs' "${stdout}"
grep -q -- '--wide' "${stdout}"
run_taskr tree_completion "${root}" __complete tree ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'001\tmilestone active MVP' "${stdout}"

# Ambiguous formatting modes should fail clearly.
run_taskr tree_bad_format "${root}" tree --tabs --wide
if [ "${exit_code}" -eq 0 ]; then
  echo "conflicting indentation modes should fail" >&2
  exit 1
fi
grep -qi "tabs\\|wide\\|format" "${stderr}"
