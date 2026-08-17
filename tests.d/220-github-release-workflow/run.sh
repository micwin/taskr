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

create_release_fixture_repo() {
  local repo="$1"
  local remote="$2"
  local version="$3"
  local build="$4"

  git init --bare "${remote}" >/dev/null
  git init -b develop "${repo}" >/dev/null
  git -C "${repo}" config user.name "Taskr Smokey"
  git -C "${repo}" config user.email "taskr-smokey@example.invalid"
  mkdir -p "${repo}/scripts"
  cp scripts/release.sh "${repo}/scripts/release.sh"
  cp scripts/prepare-release.sh "${repo}/scripts/prepare-release.sh"
  cp scripts/post-release.sh "${repo}/scripts/post-release.sh"
  chmod +x "${repo}/scripts/release.sh"
  chmod +x "${repo}/scripts/prepare-release.sh"
  chmod +x "${repo}/scripts/post-release.sh"
  printf '%s\n' "${version}" >"${repo}/VERSION"
  printf '%s\n' "${build}" >"${repo}/BUILD"
  cat >"${repo}/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

- Release fixture.
EOF
  printf 'initial\n' >"${repo}/tracked.txt"
  git -C "${repo}" add .
  git -C "${repo}" commit -m initial >/dev/null
  git -C "${repo}" remote add origin "${remote}"
  git -C "${repo}" push -u origin develop >/dev/null
  git -C "${repo}" branch release
  git -C "${repo}" push origin release >/dev/null
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
grep -q 'ref: release' .github/workflows/release.yml
grep -q 'GITHUB_REF_NAME.*release\|release.*GITHUB_REF_NAME' .github/workflows/release.yml
grep -q 'git rev-parse HEAD.*GITHUB_SHA\|GITHUB_SHA.*git rev-parse HEAD' .github/workflows/release.yml
grep -q 'contents: write' .github/workflows/release.yml
grep -q 'scripts/build.sh all --keep-build-count' .github/workflows/release.yml
grep -q 'go test ./...' .github/workflows/release.yml
grep -q 'go vet ./...' .github/workflows/release.yml
grep -q 'taskr doctor\|go run ./src/taskr doctor' .github/workflows/release.yml
grep -q 'smokey --tests-dir tests.d' .github/workflows/release.yml
grep -q 'sha256sum' .github/workflows/release.yml
grep -q 'cd dist' .github/workflows/release.yml
grep -q 'basename.*binary' .github/workflows/release.yml
grep -q 'basename.*package' .github/workflows/release.yml
grep -q 'action-gh-release' .github/workflows/release.yml
grep -q 'git config user.name "github-actions\[bot\]"' .github/workflows/release.yml
grep -q 'git config user.email' .github/workflows/release.yml
if grep -qi 'pages' .github/workflows/release.yml; then
  echo "release workflow should not publish GitHub Pages" >&2
  exit 1
fi

# Release documentation, agent policy, and changelog should describe the
# frozen-version process.
test -f RELEASING.md
test -f CHANGELOG.md
grep -q 'RELEASING.md' AGENTS.md
grep -q 'scripts/release.sh' RELEASING.md
grep -q 'scripts/prepare-release.sh' RELEASING.md
grep -q 'scripts/post-release.sh' RELEASING.md
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

# Release-note extraction should normalize accidentally wrapped bullets so
# GitHub does not render continuation lines as separate bullet points.
wrapped_changelog="${SMOKEY_STATE_DIR}/wrapped-release-notes-CHANGELOG.md"
wrapped_notes="${SMOKEY_STATE_DIR}/wrapped-release-notes.md"
cat >"${wrapped_changelog}" <<'EOF'
# Changelog

## [Unreleased]

## [0.1.0+82]

- Taskr items can now carry tags in marker frontmatter. Tags are visible in CLI
- output and generated sites, searchable with `show '#tag'`, filterable with
- `list --tags`, completed by the shell, and validated by Doctor.
- Generated Taskr sites now include status filters. Done and cancelled work is
- hidden by default, can be toggled back on, and milestones stay visible whenever
- they contain visible work.

- Added `taskr site open` with loopback serving, browser selection, positional
  site search, optional regeneration, and live watch reload.
- Added repeatable, case-insensitive `taskr list --glob` filtering over complete
  marker text.

## [0.1.0+81]

- Previous release note.
EOF
scripts/extract-release-notes.sh 0.1.0+82 "${wrapped_changelog}" >"${wrapped_notes}"
grep -qx -- '- Taskr items can now carry tags in marker frontmatter. Tags are visible in CLI' "${wrapped_notes}"
grep -qx -- '  output and generated sites, searchable with `show '\''#tag'\''`, filterable with' "${wrapped_notes}"
grep -qx -- '  `list --tags`, completed by the shell, and validated by Doctor.' "${wrapped_notes}"
grep -qx -- '- Generated Taskr sites now include status filters. Done and cancelled work is' "${wrapped_notes}"
grep -qx -- '  hidden by default, can be toggled back on, and milestones stay visible whenever' "${wrapped_notes}"
grep -qx -- '  they contain visible work.' "${wrapped_notes}"
grep -qx -- '- Added `taskr site open` with loopback serving, browser selection, positional' "${wrapped_notes}"
grep -qx -- '  site search, optional regeneration, and live watch reload.' "${wrapped_notes}"
grep -qx -- '- Added repeatable, case-insensitive `taskr list --glob` filtering over complete' "${wrapped_notes}"
grep -qx -- '  marker text.' "${wrapped_notes}"
if grep -qx -- '- output and generated sites, searchable with `show '\''#tag'\''`, filterable with' "${wrapped_notes}"; then
  echo "wrapped continuation should not remain a top-level bullet" >&2
  exit 1
fi
if grep -qx -- '- hidden by default, can be toggled back on, and milestones stay visible whenever' "${wrapped_notes}"; then
  echo "wrapped continuation should not remain a top-level bullet" >&2
  exit 1
fi

# Build a local remote for the prepare/release/post-release contract.
release_remote="${SMOKEY_STATE_DIR}/release-origin.git"
release_repo="${SMOKEY_STATE_DIR}/release-repo"
git init --bare "${release_remote}" >/dev/null
git init -b develop "${release_repo}" >/dev/null
git -C "${release_repo}" config user.name "Taskr Smokey"
git -C "${release_repo}" config user.email "taskr-smokey@example.invalid"
mkdir -p "${release_repo}/scripts"
cp scripts/release.sh "${release_repo}/scripts/release.sh"
cp scripts/prepare-release.sh "${release_repo}/scripts/prepare-release.sh"
cp scripts/post-release.sh "${release_repo}/scripts/post-release.sh"
chmod +x "${release_repo}/scripts/release.sh"
chmod +x "${release_repo}/scripts/prepare-release.sh"
chmod +x "${release_repo}/scripts/post-release.sh"
printf '0.1.0\n' >"${release_repo}/VERSION"
printf '41\n' >"${release_repo}/BUILD"
cat >"${release_repo}/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

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

# Prepare starts on clean synchronized develop, switches to release, and writes
# release preparation there without committing or pushing.
run_command prepare_success env -C "${release_repo}" scripts/prepare-release.sh
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ "$(git -C "${release_repo}" branch --show-current)" = "release" ]
grep -q 'branch=release' "${stdout}"
grep -q '^## \[0\.1\.0+41\]' "${release_repo}/CHANGELOG.md"
[ -n "$(git -C "${release_repo}" status --porcelain)" ] || {
  echo "prepare-release should leave reviewable changes on release" >&2
  exit 1
}
[ "$(git --git-dir="${release_remote}" rev-parse release)" != "$(git -C "${release_repo}" rev-parse release)" ] || {
  echo "prepare-release should not push release" >&2
  exit 1
}

# Prepare can select a raised release version on the release branch while
# preserving BUILD.
prepare_minor_remote="${SMOKEY_STATE_DIR}/prepare-minor-origin.git"
prepare_minor_repo="${SMOKEY_STATE_DIR}/prepare-minor-repo"
create_release_fixture_repo "${prepare_minor_repo}" "${prepare_minor_remote}" 1.2.3 77
run_command prepare_raise_minor env -C "${prepare_minor_repo}" scripts/prepare-release.sh --raise-minor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ "$(git -C "${prepare_minor_repo}" branch --show-current)" = "release" ]
grep -qx '1.3.0' "${prepare_minor_repo}/VERSION"
grep -qx '77' "${prepare_minor_repo}/BUILD"
grep -q '^## \[1\.3\.0+77\]' "${prepare_minor_repo}/CHANGELOG.md"
[ -n "$(git -C "${prepare_minor_repo}" status --porcelain)" ] || {
  echo "prepare-release --raise-minor should leave reviewable changes on release" >&2
  exit 1
}
[ "$(git --git-dir="${prepare_minor_remote}" rev-parse release)" != "$(git -C "${prepare_minor_repo}" rev-parse release)" ] || {
  echo "prepare-release --raise-minor should not push release" >&2
  exit 1
}

prepare_major_remote="${SMOKEY_STATE_DIR}/prepare-major-origin.git"
prepare_major_repo="${SMOKEY_STATE_DIR}/prepare-major-repo"
create_release_fixture_repo "${prepare_major_repo}" "${prepare_major_remote}" 1.2.3 77
run_command prepare_raise_major env -C "${prepare_major_repo}" scripts/prepare-release.sh --raise-major
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ "$(git -C "${prepare_major_repo}" branch --show-current)" = "release" ]
grep -qx '2.0.0' "${prepare_major_repo}/VERSION"
grep -qx '77' "${prepare_major_repo}/BUILD"
grep -q '^## \[2\.0\.0+77\]' "${prepare_major_repo}/CHANGELOG.md"

prepare_bad_remote="${SMOKEY_STATE_DIR}/prepare-bad-origin.git"
prepare_bad_repo="${SMOKEY_STATE_DIR}/prepare-bad-repo"
create_release_fixture_repo "${prepare_bad_repo}" "${prepare_bad_remote}" 1.2.3 77
run_command prepare_mutually_exclusive env -C "${prepare_bad_repo}" scripts/prepare-release.sh --raise-major --raise-minor
[ "${exit_code}" -ne 0 ] || { echo "mutually exclusive prepare raise flags should fail" >&2; exit 1; }
grep -qi 'mutually\|exclusive\|raise' "${stderr}"
[ "$(git -C "${prepare_bad_repo}" branch --show-current)" = "develop" ]
grep -qx '1.2.3' "${prepare_bad_repo}/VERSION"
grep -qx '77' "${prepare_bad_repo}/BUILD"
run_command prepare_unknown_flag env -C "${prepare_bad_repo}" scripts/prepare-release.sh --raise-potato
[ "${exit_code}" -ne 0 ] || { echo "unknown prepare flag should fail" >&2; exit 1; }
grep -qi 'unknown option\|usage' "${stderr}"
[ "$(git -C "${prepare_bad_repo}" branch --show-current)" = "develop" ]
grep -qx '1.2.3' "${prepare_bad_repo}/VERSION"
grep -qx '77' "${prepare_bad_repo}/BUILD"

# Release runs only on release, commits the prepared state, pushes release, and
# does not move develop.
develop_before_release="$(git -C "${release_repo}" rev-parse develop)"
run_command release_success env -C "${release_repo}" scripts/release.sh
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ "$(git -C "${release_repo}" branch --show-current)" = "release" ]
grep -q 'branch=release' "${stdout}"
[ -z "$(git -C "${release_repo}" status --porcelain)" ]
[ "$(git -C "${release_repo}" rev-parse develop)" = "${develop_before_release}" ]
[ "$(git -C "${release_repo}" rev-parse release)" = "$(git --git-dir="${release_remote}" rev-parse release)" ]
[ "$(git -C "${release_repo}" rev-parse release)" != "$(git -C "${release_repo}" rev-parse develop)" ]
grep -q 'prepare release 0.1.0+41' <(git -C "${release_repo}" log -1 --format=%s)

# Post-release returns to develop, merges release, and raises the next patch by default.
run_command post_release_success env -C "${release_repo}" scripts/post-release.sh
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ "$(git -C "${release_repo}" branch --show-current)" = "develop" ]
grep -qx '0.1.1' "${release_repo}/VERSION"
grep -qx '41' "${release_repo}/BUILD"
if awk '/^## \[Unreleased\]/{in_unreleased=1; next} in_unreleased && /^## \[/{exit} in_unreleased && NF{found=1} END{exit found ? 0 : 1}' "${release_repo}/CHANGELOG.md"; then
  echo "post-release should clear the Unreleased changelog staging section" >&2
  exit 1
fi
grep -q '^## \[0\.1\.0+41\]' "${release_repo}/CHANGELOG.md"
grep -q -- '- Release fixture\.' "${release_repo}/CHANGELOG.md"
grep -q 'post release 0.1.1' <(git -C "${release_repo}" log -1 --format=%s)

# Post-release supports explicit minor and major raises without changing BUILD.
post_minor_repo="${SMOKEY_STATE_DIR}/post-minor-repo"
cp -R "${release_repo}" "${post_minor_repo}"
git -C "${post_minor_repo}" switch release >/dev/null
run_command post_release_minor env -C "${post_minor_repo}" scripts/post-release.sh --raise-minor
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx '0.2.0' "${post_minor_repo}/VERSION"
grep -qx '41' "${post_minor_repo}/BUILD"

post_major_repo="${SMOKEY_STATE_DIR}/post-major-repo"
cp -R "${release_repo}" "${post_major_repo}"
git -C "${post_major_repo}" switch release >/dev/null
run_command post_release_major env -C "${post_major_repo}" scripts/post-release.sh --raise-major
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -qx '1.0.0' "${post_major_repo}/VERSION"
grep -qx '41' "${post_major_repo}/BUILD"

# Prepare rejects wrong branches, dirty trees, and unsynchronized develop before
# modifying release.
git -C "${release_repo}" switch develop >/dev/null
printf 'dirty\n' >"${release_repo}/untracked.txt"
run_command prepare_dirty env -C "${release_repo}" scripts/prepare-release.sh
[ "${exit_code}" -ne 0 ] || { echo "prepare-release with dirty tree should fail" >&2; exit 1; }
grep -qi 'dirty\|clean' "${stderr}"
rm "${release_repo}/untracked.txt"
printf 'local only\n' >>"${release_repo}/tracked.txt"
git -C "${release_repo}" add tracked.txt
git -C "${release_repo}" commit -m local-only >/dev/null
run_command prepare_unsynchronized env -C "${release_repo}" scripts/prepare-release.sh
[ "${exit_code}" -ne 0 ] || { echo "prepare-release with unpushed develop should fail" >&2; exit 1; }
grep -qi 'synchron\|origin/develop\|push develop' "${stderr}"

# Release itself only runs on release and requires a prepared clean release
# branch with the changelog entry already present.
git -C "${release_repo}" reset --hard origin/develop >/dev/null
git -C "${release_repo}" switch develop >/dev/null
run_command release_wrong_branch env -C "${release_repo}" scripts/release.sh
[ "${exit_code}" -ne 0 ] || { echo "release outside release branch should fail" >&2; exit 1; }
grep -qi 'release' "${stderr}"
