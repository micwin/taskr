#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"

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

run_command() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  "$@" >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
}

root="${SMOKEY_STATE_DIR}/release-notes-root"
cp -R "${SMOKEY_TEST_DIR}/fixtures/release-root" "${root}"

# Closing done work requires exactly one release-note intent.
run_taskr done_without_intent "${root}" status 002 done
[ "${exit_code}" -eq 2 ] || { echo "done without release-note intent should exit 2" >&2; exit 1; }
grep -qi 'release.note\|no-release-note' "${stderr}"

run_taskr done_note_and_omission "${root}" status 002 done --release-note "Visible release note" --no-release-note
[ "${exit_code}" -eq 2 ] || { echo "release-note and no-release-note together should exit 2" >&2; exit 1; }
grep -qi 'mutually\|exactly one\|release.note' "${stderr}"

# Single-line and multiline release notes are stored in the existing marker file.
run_taskr done_with_note "${root}" status 002 done --release-note "Users can see the visible change."
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^status id=002 old=reviewing new=done changed=true$' "${stdout}"
grep -q '^# Release Notes$' "${root}/001-release-notes/002-visible-change/task.md"
grep -q '^Users can see the visible change\.$' "${root}/001-release-notes/002-visible-change/task.md"

printf 'Line one.\nLine two.\n' | run_taskr done_with_stdin_note "${root}" status 003 done --release-note-stdin
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^Line one\.$' "${root}/001-release-notes/003-internal-cleanup/task.md"
grep -q '^Line two\.$' "${root}/001-release-notes/003-internal-cleanup/task.md"

# Explicit no-release-note intent is represented in frontmatter and not emitted.
run_taskr create_no_note "${root}" create task "No note work" --under 001 --status reviewing --no-edit
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
run_taskr done_no_note "${root}" status 006 done --no-release-note
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^release_note: no-release-note$' "${root}/001-release-notes/006-no-note-work/task.md"

# Doctor rejects missing and contradictory intent, and --fix only migrates safe missing intent.
run_taskr doctor_missing_or_contradictory "${root}" doctor
[ "${exit_code}" -ne 0 ] || { echo "doctor should reject missing or contradictory release-note intent" >&2; exit 1; }
grep -q '004' "${stderr}"
grep -q '005' "${stderr}"
run_taskr doctor_fix_blocked "${root}" doctor --fix
[ "${exit_code}" -ne 0 ] || { echo "doctor --fix should not partially write when contradictions exist" >&2; exit 1; }
if grep -q '^release_note: no-release-note$' "${root}/001-release-notes/004-missing-intent/task.md"; then
  echo "doctor --fix should not partially migrate when preflight finds contradictions" >&2
  exit 1
fi
rm -rf "${root}/001-release-notes/005-contradictory"
run_taskr doctor_fix_missing "${root}" doctor --fix
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^release_note: no-release-note$' "${root}/001-release-notes/004-missing-intent/task.md"
grep -qi '004\|1' "${stdout}"
run_taskr doctor_clean "${root}" doctor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }

# Release-note rendering is a release-script helper for Taskr itself, not a
# public taskr command.
run_command render_notes scripts/collect-taskr-release-notes.sh "${root}" --since-ref none
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'Users can see the visible change\.' "${stdout}"
grep -q 'Line one\.' "${stdout}"
if grep -q 'No note work\|Missing intent' "${stdout}"; then
  echo "release notes should omit explicit no-release-note items" >&2
  exit 1
fi

# release.sh should build Taskr's changelog entry from Taskr-root notes before
# pushing the release branch.
release_remote="${SMOKEY_STATE_DIR}/release-notes-origin.git"
release_repo="${SMOKEY_STATE_DIR}/release-notes-repo"
git init --bare "${release_remote}" >/dev/null
git init -b develop "${release_repo}" >/dev/null
git -C "${release_repo}" config user.name "Taskr Smokey"
git -C "${release_repo}" config user.email "taskr-smokey@example.invalid"
mkdir -p "${release_repo}/scripts"
cp scripts/release.sh "${release_repo}/scripts/release.sh"
cp scripts/collect-taskr-release-notes.sh "${release_repo}/scripts/collect-taskr-release-notes.sh"
chmod +x "${release_repo}/scripts/release.sh"
cp -R "${root}" "${release_repo}/taskr-data"
printf '0.1.0\n' >"${release_repo}/VERSION"
printf '99\n' >"${release_repo}/BUILD"
cat >"${release_repo}/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]
EOF
printf 'initial\n' >"${release_repo}/tracked.txt"
git -C "${release_repo}" add .
git -C "${release_repo}" commit -m initial >/dev/null
git -C "${release_repo}" remote add origin "${release_remote}"
git -C "${release_repo}" push -u origin develop >/dev/null
git -C "${release_repo}" branch release
git -C "${release_repo}" push origin release >/dev/null
run_command release_collects_notes env -C "${release_repo}" TASKR_ROOT=taskr-data scripts/release.sh
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^## \[0\.1\.0+99\]' "${release_repo}/CHANGELOG.md"
grep -q 'Users can see the visible change\.' "${release_repo}/CHANGELOG.md"
grep -q 'Line one\.' "${release_repo}/CHANGELOG.md"
