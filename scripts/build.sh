#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF_USAGE'
usage: scripts/build.sh <command> [options]

commands:
  binary                 Build the taskr binary.

options:
  --version-file PATH    File containing MAJOR.MINOR.PATCH (default: VERSION)
  --build-file PATH      File containing the monotonic build counter (default: BUILD)
  --output-dir DIR       Output directory (default: dist)
  --raise-minor          Increment minor and reset patch to 0
  --raise-major          Increment major and reset minor and patch to 0
  --commit SHA           Commit metadata to inject (default: git HEAD if available)
  --built-at ISO         Build timestamp to inject (default: current UTC time)
EOF_USAGE
}

fail() {
  echo "build.sh: $*" >&2
  exit 2
}

command="${1:-}"
if [ -z "${command}" ]; then
  usage
  exit 2
fi
shift

version_file="VERSION"
build_file="BUILD"
output_dir="dist"
raise_minor=false
raise_major=false
commit=""
built_at=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version-file)
      [ "$#" -ge 2 ] || fail "--version-file needs a value"
      version_file="$2"
      shift 2
      ;;
    --build-file)
      [ "$#" -ge 2 ] || fail "--build-file needs a value"
      build_file="$2"
      shift 2
      ;;
    --output-dir)
      [ "$#" -ge 2 ] || fail "--output-dir needs a value"
      output_dir="$2"
      shift 2
      ;;
    --raise-minor)
      raise_minor=true
      shift
      ;;
    --raise-major)
      raise_major=true
      shift
      ;;
    --commit)
      [ "$#" -ge 2 ] || fail "--commit needs a value"
      commit="$2"
      shift 2
      ;;
    --built-at)
      [ "$#" -ge 2 ] || fail "--built-at needs a value"
      built_at="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option $1"
      ;;
  esac
done

[ "${raise_minor}" = false ] || [ "${raise_major}" = false ] || fail "--raise-minor and --raise-major are mutually exclusive"

read_file() {
  local path="$1"
  [ -f "${path}" ] || fail "missing file ${path}"
  sed -n '1p' "${path}" | tr -d '[:space:]'
}

write_file() {
  local path="$1"
  local value="$2"
  mkdir -p "$(dirname "${path}")"
  printf '%s\n' "${value}" >"${path}"
}

version_value="$(read_file "${version_file}")"
build_value="$(read_file "${build_file}")"

if [[ ! "${version_value}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  fail "invalid version ${version_value}; expected MAJOR.MINOR.PATCH"
fi
major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

if [[ ! "${build_value}" =~ ^[0-9]+$ ]]; then
  fail "invalid build counter ${build_value}"
fi

if [ "${raise_major}" = true ]; then
  major=$((major + 1))
  minor=0
  patch=0
elif [ "${raise_minor}" = true ]; then
  minor=$((minor + 1))
  patch=0
fi

version_value="${major}.${minor}.${patch}"
build_value=$((build_value + 1))
full_version="${version_value}+${build_value}"

if [ -z "${commit}" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit="$(git rev-parse --short HEAD)"
fi
if [ -z "${built_at}" ]; then
  built_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

build_binary() {
  local output_path="$1"
  mkdir -p "$(dirname "${output_path}")"
  go build \
    -ldflags "-X main.version=${full_version} -X main.commit=${commit} -X main.builtAt=${built_at}" \
    -o "${output_path}" ./src/taskr
}

persist_version() {
  write_file "${version_file}" "${version_value}"
  write_file "${build_file}" "${build_value}"
}

case "${command}" in
binary)
  output_path="${output_dir}/taskr"
  build_binary "${output_path}"
  persist_version
  echo "built binary path=${output_path} version=${full_version}"
  ;;
*)
  fail "unknown command ${command}"
  ;;
esac
