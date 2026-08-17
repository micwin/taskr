#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
  echo "prepare-release.sh: $*" >&2
  exit 2
}

raise_major=false
raise_minor=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --raise-major)
      raise_major=true
      shift
      ;;
    --raise-minor)
      raise_minor=true
      shift
      ;;
    -h|--help)
      cat <<'EOF'
usage: scripts/prepare-release.sh [--raise-major|--raise-minor]
EOF
      exit 0
      ;;
    *)
      fail "unknown option $1"
      ;;
  esac
done
[ "${raise_major}" = false ] || [ "${raise_minor}" = false ] || fail "--raise-major and --raise-minor are mutually exclusive"

current_branch="$(git branch --show-current)"
[ "${current_branch}" = "develop" ] || fail "prepare-release must start from develop"
[ -z "$(git status --porcelain)" ] || fail "working tree must be clean"

git fetch origin
git show-ref --verify --quiet refs/remotes/origin/develop || fail "origin/develop does not exist"
[ "$(git rev-parse develop)" = "$(git rev-parse refs/remotes/origin/develop)" ] || fail "develop must be synchronized with origin/develop; push develop first"

version="$(tr -d '[:space:]' <VERSION)"
build="$(tr -d '[:space:]' <BUILD)"
[[ "${version}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || fail "invalid VERSION ${version}"
major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
[[ "${build}" =~ ^[0-9]+$ ]] || fail "invalid BUILD ${build}"
if [ "${raise_major}" = true ]; then
  major=$((major + 1))
  minor=0
  patch=0
elif [ "${raise_minor}" = true ]; then
  minor=$((minor + 1))
  patch=0
fi
version="${major}.${minor}.${patch}"
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
printf '%s\n' "${version}" >VERSION

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
