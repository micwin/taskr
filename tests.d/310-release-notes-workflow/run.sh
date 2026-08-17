#!/usr/bin/env bash
set -euo pipefail

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

# Release-note rendering is a release-script helper for Taskr itself, not a
# public taskr command.
run_command render_notes scripts/collect-taskr-release-notes.sh "${root}" --since-ref none
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'Users can see the visible change\.' "${stdout}"
if grep -q 'Internal cleanup' "${stdout}"; then
  echo "release notes should omit explicit no-release-note items" >&2
  exit 1
fi

empty_root="${SMOKEY_STATE_DIR}/release-notes-empty-root"
cp -R "${root}" "${empty_root}"
rm -rf "${empty_root}/001-release-notes/002-visible-change"
run_command render_empty scripts/collect-taskr-release-notes.sh "${empty_root}" --since-ref none
[ "${exit_code}" -eq 1 ] || { echo "release-note helper should fail when no notes are available" >&2; exit 1; }
grep -q 'no release notes found' "${stderr}"

boundary_repo="${SMOKEY_STATE_DIR}/release-notes-boundary-repo"
git init -b develop "${boundary_repo}" >/dev/null
git -C "${boundary_repo}" config user.name "Taskr Smokey"
git -C "${boundary_repo}" config user.email "taskr-smokey@example.invalid"
cp -R "${root}" "${boundary_repo}/taskr-data"
git -C "${boundary_repo}" add .
git -C "${boundary_repo}" commit -m previous >/dev/null
git -C "${boundary_repo}" tag v0.1.0+1
run_command render_unchanged_since_tag env -C "${boundary_repo}" "${PWD}/scripts/collect-taskr-release-notes.sh" taskr-data --since-ref v0.1.0+1
[ "${exit_code}" -eq 1 ] || { echo "unchanged release notes should be skipped after the boundary tag" >&2; exit 1; }
grep -q 'no release notes found' "${stderr}"
mkdir -p "${boundary_repo}/taskr-data/001-release-notes/004-new-visible-change"
cat >"${boundary_repo}/taskr-data/001-release-notes/004-new-visible-change/task.md" <<'EOF'
---
title: New visible change
status: done
created_at: 2026-08-17T00:00:00Z
updated_at: 2026-08-17T00:00:00Z
done_at: 2026-08-17T00:00:00Z
---

# Description

New completed work.

# Acceptance

- Release boundary collection can see this new marker.

# Comments

# Outcome

New work was delivered.

# Release Notes

New visible change is included after the previous release tag.
EOF
git -C "${boundary_repo}" add .
git -C "${boundary_repo}" commit -m new-note >/dev/null
run_command render_changed_since_tag env -C "${boundary_repo}" "${PWD}/scripts/collect-taskr-release-notes.sh" taskr-data --since-ref v0.1.0+1
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q 'New visible change is included after the previous release tag\.' "${stdout}"
if grep -q 'Users can see the visible change\.' "${stdout}"; then
  echo "release boundary collection should not repeat notes from the previous tag" >&2
  exit 1
fi

# prepare-release.sh should build Taskr's changelog entry from Taskr-root notes
# before release.sh commits and pushes the release branch.
release_remote="${SMOKEY_STATE_DIR}/release-notes-origin.git"
release_repo="${SMOKEY_STATE_DIR}/release-notes-repo"
git init --bare "${release_remote}" >/dev/null
git init -b develop "${release_repo}" >/dev/null
git -C "${release_repo}" config user.name "Taskr Smokey"
git -C "${release_repo}" config user.email "taskr-smokey@example.invalid"
mkdir -p "${release_repo}/scripts"
cp scripts/release.sh "${release_repo}/scripts/release.sh"
cp scripts/prepare-release.sh "${release_repo}/scripts/prepare-release.sh"
cp scripts/collect-taskr-release-notes.sh "${release_repo}/scripts/collect-taskr-release-notes.sh"
chmod +x "${release_repo}/scripts/release.sh"
chmod +x "${release_repo}/scripts/prepare-release.sh"
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
run_command prepare_collects_notes env -C "${release_repo}" TASKR_ROOT=taskr-data scripts/prepare-release.sh
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^## \[0\.1\.0+99\]' "${release_repo}/CHANGELOG.md"
grep -q 'Users can see the visible change\.' "${release_repo}/CHANGELOG.md"
run_command release_collects_notes env -C "${release_repo}" scripts/release.sh
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
