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

# Copy a valid root for status and open workflows.
root="${SMOKEY_STATE_DIR}/status-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"

# Parent work cannot close before unfinished children.
run_taskr status_parent_blocked "${root}" status 003 done
[ "${exit_code}" -ne 0 ] || { echo "parent should not close before child" >&2; exit 1; }
grep -q "004" "${stderr}"

# Closing child first should allow the parent to close.
run_taskr status_child_done "${root}" status 004 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "status id=004" "${stdout}"
grep -q "new=done" "${stdout}"
run_taskr status_parent_done "${root}" status 003 done
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "status id=003" "${stdout}"
grep -q "new=done" "${stdout}"

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
