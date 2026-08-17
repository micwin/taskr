#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
  echo "release.sh: $*" >&2
  exit 2
}

current_branch="$(git branch --show-current)"
[ "${current_branch}" = "develop" ] || fail "release must run from develop"
[ -z "$(git status --porcelain)" ] || fail "working tree must be clean"

git fetch origin
git show-ref --verify --quiet refs/remotes/origin/develop || fail "origin/develop does not exist"
[ "$(git rev-parse HEAD)" = "$(git rev-parse refs/remotes/origin/develop)" ] || fail "develop must be synchronized with origin/develop; push develop first"

version="$(tr -d '[:space:]' <VERSION)"
build="$(tr -d '[:space:]' <BUILD)"
[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "invalid VERSION ${version}"
[[ "${build}" =~ ^[0-9]+$ ]] || fail "invalid BUILD ${build}"
release_version="${version}+${build}"
if ! grep -Fq "## [${release_version}]" CHANGELOG.md; then
  taskr_root="${TASKR_ROOT:-taskr}"
  notes="$(scripts/collect-taskr-release-notes.sh "${taskr_root}" --since-ref "$(git describe --tags --abbrev=0 2>/dev/null || echo none)")" || fail "could not collect Taskr release notes"
  tmp_changelog="$(mktemp)"
  awk -v version="${release_version}" -v notes="${notes}" '
    BEGIN { inserted = 0 }
    /^## \[Unreleased\]/ {
      print
      print ""
      print "## [" version "] - " strftime("%Y-%m-%d")
      print ""
      print notes
      inserted = 1
      next
    }
    { print }
    END { if (!inserted) exit 1 }
  ' CHANGELOG.md >"${tmp_changelog}" || { rm -f "${tmp_changelog}"; fail "CHANGELOG.md needs a ## [Unreleased] entry"; }
  mv "${tmp_changelog}" CHANGELOG.md
  git add CHANGELOG.md
  git commit -m "docs: prepare release ${release_version}"
fi

if git ls-remote --exit-code --tags origin "refs/tags/v${release_version}" >/dev/null 2>&1; then
  fail "tag v${release_version} already exists; rerun or repair the existing GitHub Actions release"
fi

return_to_develop=false
restore_branch() {
  if [ "${return_to_develop}" = true ] && [ "$(git branch --show-current)" != "develop" ]; then
    git switch develop >/dev/null 2>&1 || true
  fi
}
trap restore_branch EXIT

if git show-ref --verify --quiet refs/remotes/origin/release; then
  if git show-ref --verify --quiet refs/heads/release; then
    git switch release
    return_to_develop=true
    git merge --ff-only origin/release
  else
    git switch --track -c release origin/release
    return_to_develop=true
  fi
else
  git switch -c release develop
  return_to_develop=true
fi

git merge --ff-only develop
git push -u origin release
git switch develop
return_to_develop=false

echo "release branch updated version=${release_version} commit=$(git rev-parse --short HEAD)"
