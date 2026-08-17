#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
  echo "post-release.sh: $*" >&2
  exit 2
}

raise="patch"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --raise-patch)
      raise="patch"
      shift
      ;;
    --raise-minor)
      raise="minor"
      shift
      ;;
    --raise-major)
      raise="major"
      shift
      ;;
    -h|--help)
      cat <<'EOF'
usage: scripts/post-release.sh [--raise-patch|--raise-minor|--raise-major]
EOF
      exit 0
      ;;
    *)
      fail "unknown option $1"
      ;;
  esac
done

[ -z "$(git status --porcelain)" ] || fail "working tree must be clean"
git show-ref --verify --quiet refs/heads/release || fail "local release branch does not exist"
git show-ref --verify --quiet refs/heads/develop || fail "local develop branch does not exist"

git switch develop
git merge --no-edit release

version="$(tr -d '[:space:]' <VERSION)"
build="$(tr -d '[:space:]' <BUILD)"
[[ "${version}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || fail "invalid VERSION ${version}"
major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
[[ "${build}" =~ ^[0-9]+$ ]] || fail "invalid BUILD ${build}"

case "${raise}" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
esac

next_version="${major}.${minor}.${patch}"
printf '%s\n' "${next_version}" >VERSION
git add VERSION
git commit -m "post release ${next_version}"

echo "post release prepared version=${next_version} build=${build}"
