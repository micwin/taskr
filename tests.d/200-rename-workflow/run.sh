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

# Copy a valid root and add related files plus an ambiguous selector candidate.
root="${SMOKEY_STATE_DIR}/rename-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
task_dir="${root}/001-mvp/003-workflows-definieren"
mkdir -p "${task_dir}/files"
cat >"${task_dir}/files/files.md" <<'EOF'
---
title: Workflow files
created_at: 2026-06-04T00:00:00Z
updated_at: 2026-06-04T00:00:00Z
---

# Description

Files attached to the workflow task.

# Acceptance

- Rename preserves this directory.

# Comments

# Outcome
EOF
printf '%s\n' 'preserve this attachment' >"${task_dir}/files/notes.txt"
mkdir -p "${root}/001-mvp/006-workflow-polish"
cat >"${root}/001-mvp/006-workflow-polish/task.md" <<'EOF'
---
title: Workflow polish
status: open
created_at: 2026-06-04T00:00:00Z
updated_at: 2026-06-04T00:00:00Z
---

# Description

Second workflow match for rename ambiguity tests.

# Acceptance

- Rename reports this candidate without changing it.

# Comments

# Outcome
EOF

# Help and examples should document the default and expert rename forms.
run_taskr rename_help "${root}" rename --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr rename <selector> <new-title>' "${stdout}"
grep -q -- '--slug' "${stdout}"
grep -q -- '--keep-slug' "${stdout}"
run_taskr rename_examples "${root}" examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'taskr rename 003 "Plan delivery workflows"' "${stdout}"
grep -q 'taskr rename 003 "Plan delivery workflows" --slug delivery-plan' "${stdout}"
grep -q 'taskr rename 003 "Plan delivery workflows" --keep-slug' "${stdout}"

# Selector completion should offer every item type accepted by rename.
run_taskr rename_completion "${root}" __complete rename ""
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'001\tmilestone active MVP' "${stdout}"
grep -qx $'003\ttask active Define workflows' "${stdout}"
grep -qx $'004\tsubtask designing Define selectors' "${stdout}"

# Default rename should update title and derived slug while preserving the subtree.
run_taskr rename_default "${root}" rename 003 "Plan delivery workflows"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'renamed id=003' "${stdout}"
new_task_dir="${root}/001-mvp/003-plan-delivery-workflows"
test -f "${new_task_dir}/task.md"
test ! -e "${task_dir}"
grep -q '^title: Plan delivery workflows$' "${new_task_dir}/task.md"
grep -q '^updated_at:' "${new_task_dir}/task.md"
if grep -q '^updated_at: 2026-06-04T00:00:00Z$' "${new_task_dir}/task.md"; then
  echo "real rename should update updated_at" >&2
  exit 1
fi
grep -q 'Active task with an unfinished child' "${new_task_dir}/task.md"
grep -q 'Fixture data for Smokey' "${new_task_dir}/task.md"
test -f "${new_task_dir}/004-define-selectors/subtask.md"
grep -qx 'preserve this attachment' "${new_task_dir}/files/notes.txt"

# Custom slug should rename a milestone without changing its id or descendants.
run_taskr rename_custom_slug "${root}" rename 001 "Minimum viable product" --slug "Initial Release"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'renamed id=001' "${stdout}"
milestone_dir="${root}/001-initial-release"
test -f "${milestone_dir}/milestone.md"
test ! -e "${root}/001-mvp"
grep -q '^title: Minimum viable product$' "${milestone_dir}/milestone.md"
test -f "${milestone_dir}/003-plan-delivery-workflows/task.md"

# Keep-slug should change only a subtask title.
subtask_dir="${milestone_dir}/003-plan-delivery-workflows/004-define-selectors"
run_taskr rename_keep_slug "${root}" rename 004 "Resolve item selectors" --keep-slug
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'renamed id=004' "${stdout}"
test -f "${subtask_dir}/subtask.md"
grep -q '^title: Resolve item selectors$' "${subtask_dir}/subtask.md"

# Repeating the same title-only rename should leave the marker byte-identical.
before_noop="$(sha256sum "${subtask_dir}/subtask.md" | cut -d' ' -f1)"
run_taskr rename_noop "${root}" rename 004 "Resolve item selectors" --keep-slug
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'changed=false' "${stdout}"
after_noop="$(sha256sum "${subtask_dir}/subtask.md" | cut -d' ' -f1)"
[ "${before_noop}" = "${after_noop}" ] || { echo "no-op rename changed marker" >&2; exit 1; }

# Missing and ambiguous selectors should fail with candidate details and exit 2.
run_taskr rename_missing "${root}" rename missing "Missing item"
[ "${exit_code}" -eq 2 ] || { echo "missing rename selector should exit 2" >&2; exit 1; }
grep -qi 'not found\|no match' "${stderr}"
run_taskr rename_ambiguous "${root}" rename workflow "Ambiguous item"
[ "${exit_code}" -eq 2 ] || { echo "ambiguous rename selector should exit 2" >&2; exit 1; }
grep -qi 'ambiguous' "${stderr}"
grep -q '003 Plan delivery workflows' "${stderr}"
grep -q '006 Workflow polish' "${stderr}"

# Invalid flags, empty values, and sibling slug collisions should be rejected atomically.
run_taskr rename_two_slug_modes "${root}" rename 005 "Renamed work" --slug renamed-work --keep-slug
[ "${exit_code}" -eq 2 ] || { echo "mutually exclusive rename flags should exit 2" >&2; exit 1; }
grep -qi 'exclusive\|together' "${stderr}"
run_taskr rename_empty_title "${root}" rename 005 "   "
[ "${exit_code}" -eq 2 ] || { echo "empty rename title should exit 2" >&2; exit 1; }
grep -qi 'title.*empty\|empty.*title' "${stderr}"
run_taskr rename_empty_slug "${root}" rename 005 "Renamed work" --slug '!!!'
[ "${exit_code}" -eq 2 ] || { echo "empty normalized slug should exit 2" >&2; exit 1; }
grep -qi 'slug.*empty\|empty.*slug' "${stderr}"
run_taskr rename_collision "${root}" rename 005 "Workflow polish"
[ "${exit_code}" -eq 2 ] || { echo "sibling slug collision should exit 2" >&2; exit 1; }
grep -qi 'duplicate\|collision\|exists' "${stderr}"
test -f "${milestone_dir}/005-open-work/task.md"
grep -q '^title: Open work$' "${milestone_dir}/005-open-work/task.md"

# The resulting root should remain structurally valid after successful and rejected renames.
run_taskr doctor_after_rename "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^ok root=' "${stdout}"
