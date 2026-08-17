#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
  echo "release.sh: $*" >&2
  exit 2
}

current_branch="$(git branch --show-current)"
[ "${current_branch}" = "release" ] || fail "release must run from release"
git fetch origin
git show-ref --verify --quiet refs/remotes/origin/release || fail "origin/release does not exist; run prepare-release first"

version="$(tr -d '[:space:]' <VERSION)"
build="$(tr -d '[:space:]' <BUILD)"
[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "invalid VERSION ${version}"
[[ "${build}" =~ ^[0-9]+$ ]] || fail "invalid BUILD ${build}"
release_version="${version}+${build}"
grep -Fq "## [${release_version}]" CHANGELOG.md || fail "CHANGELOG.md needs a ## [${release_version}] entry; run prepare-release first"

if git ls-remote --exit-code --tags origin "refs/tags/v${release_version}" >/dev/null 2>&1; then
  fail "tag v${release_version} already exists; rerun or repair the existing GitHub Actions release"
fi

git add -A
git commit -m "prepare release ${release_version}"
git push -u origin release

echo "release branch pushed version=${release_version} branch=release commit=$(git rev-parse --short HEAD)"
