#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
  echo "prepare-release.sh: $*" >&2
  exit 2
}

current_branch="$(git branch --show-current)"
[ "${current_branch}" = "develop" ] || fail "prepare-release must start from develop"
[ -z "$(git status --porcelain)" ] || fail "working tree must be clean"

git fetch origin
git show-ref --verify --quiet refs/remotes/origin/develop || fail "origin/develop does not exist"
[ "$(git rev-parse develop)" = "$(git rev-parse refs/remotes/origin/develop)" ] || fail "develop must be synchronized with origin/develop; push develop first"

version="$(tr -d '[:space:]' <VERSION)"
build="$(tr -d '[:space:]' <BUILD)"
[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "invalid VERSION ${version}"
[[ "${build}" =~ ^[0-9]+$ ]] || fail "invalid BUILD ${build}"
release_version="${version}+${build}"
notes=""
taskr_root="${TASKR_ROOT:-taskr}"
if [ -x scripts/collect-taskr-release-notes.sh ] && [ -d "${taskr_root}" ]; then
  since_ref="$(git describe --tags --abbrev=0 2>/dev/null || echo none)"
  notes="$(scripts/collect-taskr-release-notes.sh "${taskr_root}" --since-ref "${since_ref}" 2>/dev/null || true)"
fi

if git show-ref --verify --quiet refs/heads/release; then
  git switch release
  git reset --hard develop >/dev/null
else
  git switch -c release develop
fi
[ "$(git branch --show-current)" = "release" ] || fail "prepare-release failed to switch to release"

if grep -Fq "## [${release_version}]" CHANGELOG.md; then
  echo "release already prepared version=${release_version}"
  exit 0
fi

tmp_changelog="$(mktemp)"
awk -v version="${release_version}" -v notes="${notes}" '
  BEGIN { inserted = 0 }
  /^## \[Unreleased\]/ {
    print
    print ""
    print "## [" version "]"
    if (notes != "") {
      print ""
      print notes
    }
    inserted = 1
    next
  }
  { print }
  END { if (!inserted) exit 1 }
' CHANGELOG.md >"${tmp_changelog}" || { rm -f "${tmp_changelog}"; fail "CHANGELOG.md needs a ## [Unreleased] entry"; }
mv "${tmp_changelog}" CHANGELOG.md

echo "prepared release version=${release_version} branch=release"
