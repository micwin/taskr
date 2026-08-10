#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
stdout="${SMOKEY_STATE_DIR}/examples.stdout"
stderr="${SMOKEY_STATE_DIR}/examples.stderr"

"${TASKR_BIN}" examples >"${stdout}" 2>"${stderr}"

grep -q "Taskr workflow examples" "${stdout}"
grep -q "taskr init" "${stdout}"
grep -q 'taskr create milestone "MVP" --no-edit' "${stdout}"
grep -q 'taskr create task "Define workflows" --under 001 --no-edit' "${stdout}"
grep -q 'taskr create subtask "Define selectors" --under 002 --no-edit' "${stdout}"
grep -q "taskr open 002" "${stdout}"
grep -q 'taskr comment 002 "Reviewed with Michael"' "${stdout}"
grep -q "taskr comment 002 --stdin" "${stdout}"
grep -q "taskr tree" "${stdout}"
grep -q "taskr tree 001 --all" "${stdout}"
grep -q "taskr tree 001 --ascii" "${stdout}"
grep -q "taskr show 002 --meta" "${stdout}"
grep -q "taskr list --type task --status open" "${stdout}"
grep -q "taskr list --type task --status active --under 001" "${stdout}"
grep -q "taskr list --all --type task --status done --under 001" "${stdout}"
grep -q "taskr list --all --type task --status cancelled --under 001" "${stdout}"
grep -q "taskr status 001 done" "${stdout}"
grep -q "taskr archive 002 --to 2026" "${stdout}"

"${TASKR_BIN}" --help >"${stdout}" 2>"${stderr}"
grep -q "examples" "${stdout}"
