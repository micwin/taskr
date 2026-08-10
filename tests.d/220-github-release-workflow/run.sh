#!/usr/bin/env bash
set -euo pipefail

# Run a command and capture its outputs for assertions.
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

# Frozen builds should preserve both version files and stamp every artifact consistently.
version_file="${SMOKEY_STATE_DIR}/release-VERSION"
build_file="${SMOKEY_STATE_DIR}/release-BUILD"
output_dir="${SMOKEY_STATE_DIR}/release-dist"
work_dir="${SMOKEY_STATE_DIR}/release-work"
printf '0.1.0\n' >"${version_file}"
printf '41\n' >"${build_file}"
run_command build_frozen ./scripts/build.sh all \
  --keep-build-count \
  --version-file "${version_file}" \
  --build-file "${build_file}" \
  --output-dir "${output_dir}" \
  --work-dir "${work_dir}" \
  --commit abcdef1 \
  --built-at 2026-08-10T12:00:00Z
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "built binary path=${output_dir}/taskr version=0.1.0+41" "${stdout}"
grep -q "built package path=${output_dir}/taskr_0.1.0+41-1_amd64.deb version=0.1.0+41-1" "${stdout}"
grep -qx '0.1.0' "${version_file}"
grep -qx '41' "${build_file}"
"${output_dir}/taskr" version | grep -q '^taskr version 0.1.0+41 commit=abcdef1 built_at=2026-08-10T12:00:00Z$'
dpkg-deb --field "${output_dir}/taskr_0.1.0+41-1_amd64.deb" Version | grep -q '^0.1.0+41-1$'

# Frozen builds must reject flags that would alter VERSION.
run_command frozen_raise_minor ./scripts/build.sh binary \
  --keep-build-count \
  --raise-minor \
  --version-file "${version_file}" \
  --build-file "${build_file}" \
  --output-dir "${output_dir}"
[ "${exit_code}" -eq 2 ] || { echo "--keep-build-count with --raise-minor should exit 2" >&2; exit 1; }
grep -qi 'keep-build-count.*raise-minor\|raise-minor.*keep-build-count\|mutually exclusive' "${stderr}"
grep -qx '0.1.0' "${version_file}"
grep -qx '41' "${build_file}"

# CI and release workflows should expose separate verification and publication triggers.
test -f .github/workflows/ci.yml
test -f .github/workflows/release.yml
grep -q '^name: .*CI' .github/workflows/ci.yml
grep -q 'pull_request:' .github/workflows/ci.yml
grep -q 'develop' .github/workflows/ci.yml
grep -q 'go test ./...' .github/workflows/ci.yml
grep -q 'go vet ./...' .github/workflows/ci.yml
grep -q 'taskr doctor\|go run ./src/taskr doctor' .github/workflows/ci.yml
grep -q 'smokey --tests-dir tests.d' .github/workflows/ci.yml
grep -q '^name: .*Release' .github/workflows/release.yml
grep -q 'release' .github/workflows/release.yml
grep -q 'contents: write' .github/workflows/release.yml
grep -q 'scripts/build.sh all --keep-build-count' .github/workflows/release.yml
grep -q 'go test ./...' .github/workflows/release.yml
grep -q 'go vet ./...' .github/workflows/release.yml
grep -q 'taskr doctor\|go run ./src/taskr doctor' .github/workflows/release.yml
grep -q 'smokey --tests-dir tests.d' .github/workflows/release.yml
grep -q 'sha256sum' .github/workflows/release.yml
grep -q 'action-gh-release' .github/workflows/release.yml
grep -q 'git config user.name "github-actions\[bot\]"' .github/workflows/release.yml
grep -q 'git config user.email' .github/workflows/release.yml
if grep -qi 'pages' .github/workflows/release.yml; then
  echo "release workflow should not publish GitHub Pages" >&2
  exit 1
fi

# Release documentation and changelog should describe the frozen-version process.
test -f RELEASING.md
test -f CHANGELOG.md
grep -q 'scripts/release.sh' RELEASING.md
grep -q -- '--keep-build-count' RELEASING.md
grep -qi 'VERSION.*BUILD\|BUILD.*VERSION' RELEASING.md
grep -qi 'failed release\|failure' RELEASING.md
grep -q '^# Changelog' CHANGELOG.md

# Release-note extraction accepts dated headings and stops at the next release.
release_changelog="${SMOKEY_STATE_DIR}/release-notes-CHANGELOG.md"
release_notes="${SMOKEY_STATE_DIR}/release-notes.md"
cat >"${release_changelog}" <<'EOF'
# Changelog

## [Unreleased]

## [0.1.0+41] - 2026-08-10

- Expected release note.

## [0.1.0+40] - 2026-08-09

- Previous release note.
EOF
scripts/extract-release-notes.sh 0.1.0+41 "${release_changelog}" >"${release_notes}"
grep -qx -- '- Expected release note.' "${release_notes}"
if grep -q 'Previous release note' "${release_notes}"; then
  echo "release notes should stop at the next release heading" >&2
  exit 1
fi
run_command missing_release_notes scripts/extract-release-notes.sh 0.1.0+42 "${release_changelog}"
[ "${exit_code}" -ne 0 ] || { echo "missing release notes should fail" >&2; exit 1; }

# Build a local remote whose release branch can fast-forward to synchronized develop.
release_remote="${SMOKEY_STATE_DIR}/release-origin.git"
release_repo="${SMOKEY_STATE_DIR}/release-repo"
git init --bare "${release_remote}" >/dev/null
git init -b develop "${release_repo}" >/dev/null
git -C "${release_repo}" config user.name "Taskr Smokey"
git -C "${release_repo}" config user.email "taskr-smokey@example.invalid"
mkdir -p "${release_repo}/scripts"
cp scripts/release.sh "${release_repo}/scripts/release.sh"
chmod +x "${release_repo}/scripts/release.sh"
printf '0.1.0\n' >"${release_repo}/VERSION"
printf '41\n' >"${release_repo}/BUILD"
cat >"${release_repo}/CHANGELOG.md" <<'EOF'
# Changelog

## [0.1.0+41]

- Release fixture.
EOF
printf 'initial\n' >"${release_repo}/tracked.txt"
git -C "${release_repo}" add .
git -C "${release_repo}" commit -m initial >/dev/null
git -C "${release_repo}" remote add origin "${release_remote}"
git -C "${release_repo}" push -u origin develop >/dev/null
git -C "${release_repo}" branch release
git -C "${release_repo}" push origin release >/dev/null
printf 'release candidate\n' >>"${release_repo}/tracked.txt"
git -C "${release_repo}" add tracked.txt
git -C "${release_repo}" commit -m candidate >/dev/null
git -C "${release_repo}" push origin develop >/dev/null

# A valid release should fast-forward and push release, then return to develop.
run_command release_success env -C "${release_repo}" scripts/release.sh
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ "$(git -C "${release_repo}" branch --show-current)" = "develop" ]
[ "$(git -C "${release_repo}" rev-parse develop)" = "$(git --git-dir="${release_remote}" rev-parse release)" ]

# Wrong branches, dirty trees, and unsynchronized develop should fail before pushing.
git -C "${release_repo}" switch release >/dev/null
run_command release_wrong_branch env -C "${release_repo}" scripts/release.sh
[ "${exit_code}" -ne 0 ] || { echo "release outside develop should fail" >&2; exit 1; }
grep -qi 'develop' "${stderr}"
git -C "${release_repo}" switch develop >/dev/null
printf 'dirty\n' >"${release_repo}/untracked.txt"
run_command release_dirty env -C "${release_repo}" scripts/release.sh
[ "${exit_code}" -ne 0 ] || { echo "release with dirty tree should fail" >&2; exit 1; }
grep -qi 'dirty\|clean' "${stderr}"
rm "${release_repo}/untracked.txt"
printf 'local only\n' >>"${release_repo}/tracked.txt"
git -C "${release_repo}" add tracked.txt
git -C "${release_repo}" commit -m local-only >/dev/null
run_command release_unsynchronized env -C "${release_repo}" scripts/release.sh
[ "${exit_code}" -ne 0 ] || { echo "release with unpushed develop should fail" >&2; exit 1; }
grep -qi 'synchron\|origin/develop\|push develop' "${stderr}"
