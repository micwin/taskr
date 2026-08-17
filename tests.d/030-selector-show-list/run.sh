#!/usr/bin/env bash
set -euo pipefail


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

# Copy a valid root and add a second workflow-named task for ambiguity tests.
root="${SMOKEY_STATE_DIR}/selector-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
mkdir -p "${root}/001-mvp/006-workflow-polish"
cat >"${root}/001-mvp/006-workflow-polish/task.md" <<'EOF'
---
title: Workflow polish
status: active
created_at: 2026-06-04T00:00:00Z
updated_at: 2026-06-04T00:00:00Z
---

# Description

Second workflow match for selector ambiguity.

# Acceptance

- Selector tests can detect ambiguous workflow matches.

# Comments

- 2026-06-04: Generated in Smokey state.

# Outcome
EOF

# Selectors should resolve by ID, slug, and exact title.
run_taskr show_id "${root}" show 001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^ID: 001$' "${stdout}"
grep -q '^Type: milestone$' "${stdout}"
grep -q '^# Description$' "${stdout}"
grep -q '^# Acceptance$' "${stdout}"
grep -q '^# Comments$' "${stdout}"
grep -q '^# Outcome$' "${stdout}"
run_taskr show_slug "${root}" show mvp
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Title: MVP$' "${stdout}"
run_taskr show_title "${root}" show "Define workflows"
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^ID: 003$' "${stdout}"
grep -q 'Active task with an unfinished child' "${stdout}"
grep -q 'Fixture data for Smokey' "${stdout}"

# Metadata mode should include frontmatter facts and omit the Markdown body.
run_taskr show_meta "${root}" show 003 --meta
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^ID: 003$' "${stdout}"
grep -q '^Title: Define workflows$' "${stdout}"
grep -q '^Status: active$' "${stdout}"
grep -q '^Tags: #(release,website)$' "${stdout}"
grep -q '^Created at:' "${stdout}"
grep -q '^Updated at:' "${stdout}"
if grep -q '^# Description$' "${stdout}"; then
  echo "show --meta should omit the Markdown body" >&2
  exit 1
fi

# Default list output should be stable and omit terminal items.
run_taskr list_root "${root}" list
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "001 milestone active #(public,website) MVP" "${stdout}"
if grep -q "002 task done #internal Define directory structure" "${stdout}"; then
  echo "default list should hide done items" >&2
  exit 1
fi
run_taskr list_root_all "${root}" list --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "002 task done #internal Define directory structure" "${stdout}"
run_taskr list_under "${root}" list --under 001
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "003 task active #(release,website) Define workflows" "${stdout}"
run_taskr list_filtered "${root}" list --type task --status active
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "003 task active #(release,website) Define workflows" "${stdout}"

# Missing and ambiguous selectors should fail with useful diagnostics.
run_taskr show_missing "${root}" show does-not-exist
[ "${exit_code}" -ne 0 ] || { echo "missing selector should fail" >&2; exit 1; }
grep -qi "not found\\|no match" "${stderr}"
run_taskr show_ambiguous "${root}" show workflow
[ "${exit_code}" -ne 0 ] || { echo "ambiguous selector should fail" >&2; exit 1; }
grep -qi "ambiguous\\|multiple\\|candidates" "${stderr}"
grep -q '003 Define workflows' "${stderr}"
grep -q '006 Workflow polish' "${stderr}"
run_taskr list_bad_status "${root}" list --status nonsense
[ "${exit_code}" -ne 0 ] || { echo "unknown status filter should fail" >&2; exit 1; }
grep -qi "status\\|unknown\\|invalid" "${stderr}"
