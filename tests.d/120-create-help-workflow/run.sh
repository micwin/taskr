#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
stdout="${SMOKEY_STATE_DIR}/create_help.stdout"
stderr="${SMOKEY_STATE_DIR}/create_help.stderr"

"${TASKR_BIN}" create --help >"${stdout}" 2>"${stderr}"

grep -q "taskr create {milestone|task|subtask} <title>" "${stdout}"
grep -q "marker filename: milestone.md, task.md, or" "${stdout}"
grep -q "subtask.md" "${stdout}"
