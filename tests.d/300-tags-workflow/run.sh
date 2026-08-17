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

tag_root="${SMOKEY_STATE_DIR}/tag-workflow-root"
cp -R "${TASKR_BASE_ROOT}" "${tag_root}"

# Doctor accepts valid mixed-case tag input and normalizes internally.
run_taskr doctor_valid "${tag_root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Doctor rejects invalid tag characters and duplicate normalized tags.
for case in invalid-digit invalid-hash duplicate-normalized; do
  invalid_root="${SMOKEY_STATE_DIR}/${case}-root"
  mkdir -p "${invalid_root}"
  cp -R "${SMOKEY_TEST_DIR}/fixtures/invalid-tags/"*"${case}" "${invalid_root}/"
  run_taskr "doctor_${case}" "${invalid_root}" doctor
  [ "${exit_code}" -ne 0 ] || { echo "${case} tags should fail doctor" >&2; exit 1; }
  grep -qi "tag" "${stderr}"
done
grep -qi "release1" "${SMOKEY_STATE_DIR}/doctor_invalid-digit.stderr"
grep -qi "#release" "${SMOKEY_STATE_DIR}/doctor_invalid-hash.stderr"
grep -qi "duplicate" "${SMOKEY_STATE_DIR}/doctor_duplicate-normalized.stderr"

# Show resolves an exact #tag across every item type and reports ambiguity.
run_taskr show_copy "${tag_root}" show '#copy'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^ID: 004$' "${stdout}"
grep -q '^Tags: #copy$' "${stdout}"
run_taskr show_website_ambiguous "${tag_root}" show '#website'
[ "${exit_code}" -ne 0 ] || { echo "ambiguous tag lookup should fail" >&2; exit 1; }
grep -qi 'ambiguous selector "#website"' "${stderr}"
grep -q '001 MVP' "${stderr}"
grep -q '003 Define workflows' "${stderr}"

# List filters tags case-insensitively with AND semantics and compact display.
run_taskr list_website "${tag_root}" list --tags WEBSITE --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '001 milestone active #(public,website) MVP' "${stdout}"
grep -q '003 task active #(release,website) Define workflows' "${stdout}"
if grep -q '002 task done #internal Define directory structure' "${stdout}"; then
  echo "single tag filter should exclude unrelated tags" >&2
  exit 1
fi
run_taskr list_website_release "${tag_root}" list --tags website,release --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '003 task active #(release,website) Define workflows' "${stdout}"
if grep -q '001 milestone active #(public,website) MVP' "${stdout}"; then
  echo "AND tag filter should exclude partial matches" >&2
  exit 1
fi

# Tree and report include compact tags on item rows without empty decorations.
run_taskr tree_tags "${tag_root}" tree --all
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '001 \[milestone active\] #(public,website) MVP' "${stdout}"
grep -q '003 \[task active\] #(release,website) Define workflows' "${stdout}"
grep -q '004 \[subtask designing\] #copy Define selectors' "${stdout}"
run_taskr report_tags "${tag_root}" report
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '003 \[active\] #(release,website) Define workflows' "${stdout}"

# Completion suggests known normalized tags on tag-aware read-only surfaces.
run_taskr complete_show_tag "${tag_root}" __complete show '#'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'#website\t tag' "${stdout}"
grep -qx $'#release\t tag' "${stdout}"
run_taskr complete_list_tags "${tag_root}" __complete list --tags website,
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx $'release\t tag' "${stdout}"
grep -qx $'public\t tag' "${stdout}"

# Mutating selectors do not accept tag selectors as targets.
run_taskr status_tag_rejected "${tag_root}" status '#copy' reviewing
[ "${exit_code}" -ne 0 ] || { echo "mutating tag selector should fail" >&2; exit 1; }
grep -qi 'not found\|tag\|selector' "${stderr}"
