#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: scripts/build.sh <command> [options]

commands:
  binary                 Build the taskr binary.
  deb                    Build a Debian package.
  all                    Build the binary and Debian package.
  install-completion     Install shell completion for the current user.

options:
  --version-file PATH    File containing MAJOR.MINOR.PATCH (default: VERSION)
  --build-file PATH      File containing the monotonic build counter (default: BUILD)
  --output-dir DIR       Output directory (default: dist)
  --work-dir DIR         Build work directory (default: work)
  --raise-minor          Increment minor and reset patch to 0
  --raise-major          Increment major and reset minor and patch to 0
  --commit SHA           Commit metadata to inject (default: git HEAD if available)
  --built-at ISO         Build timestamp to inject (default: current UTC time)
  --install-deb          Install the just-built .deb with sudo apt install
  --shell PATH           Shell path/name for install-completion (default: SHELL)
EOF
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
work_dir="work"
raise_minor=false
raise_major=false
install_deb=false
commit=""
built_at=""
shell_name="${SHELL:-}"

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
    --work-dir)
      [ "$#" -ge 2 ] || fail "--work-dir needs a value"
      work_dir="$2"
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
    --install-deb)
      install_deb=true
      shift
      ;;
    --shell)
      [ "$#" -ge 2 ] || fail "--shell needs a value"
      shell_name="$2"
      shift 2
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

debian_revision="1"
package_version="${full_version}-${debian_revision}"
arch="$(dpkg --print-architecture 2>/dev/null || true)"
[ -n "${arch}" ] || arch="amd64"

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

build_deb() {
  local package_root="${work_dir}/deb/taskr"
  package_path="${output_dir}/taskr_${package_version}_${arch}.deb"

  rm -rf "${package_root}"
  mkdir -p "${package_root}/DEBIAN" "${package_root}/usr/bin"
  build_binary "${package_root}/usr/bin/taskr"
  chmod 0755 "${package_root}/usr/bin/taskr"
  cat >"${package_root}/DEBIAN/control" <<EOF
Package: taskr
Version: ${package_version}
Section: utils
Priority: optional
Architecture: ${arch}
Maintainer: Michael <michael@example.local>
Description: Local-first task management for command-line workflows
EOF
  mkdir -p "${output_dir}"
  dpkg-deb --build "${package_root}" "${package_path}" >/dev/null
  echo "built package path=${package_path} version=${package_version}"
}

install_deb_package() {
  local install_path="${package_path}"
  if [[ "${install_path}" != /* ]]; then
    install_path="./${install_path}"
  fi
  sudo apt install "${install_path}"
}

completion_shell() {
  basename "${shell_name:-}"
}

completion_rc_path() {
  case "$(completion_shell)" in
  bash)
    if [ -f "${HOME}/.bashrc" ] || [ ! -f "${HOME}/.bash_profile" ]; then
      echo "${HOME}/.bashrc"
    else
      echo "${HOME}/.bash_profile"
    fi
    ;;
  zsh)
    echo "${ZDOTDIR:-${HOME}}/.zshrc"
    ;;
  fish)
    echo "${XDG_CONFIG_HOME:-${HOME}/.config}/fish/conf.d/taskr.fish"
    ;;
  *)
    return 1
    ;;
  esac
}

completion_block() {
  case "$(completion_shell)" in
  bash)
    cat <<'EOF'
# >>> taskr completion >>>
source <(taskr completion bash)
# <<< taskr completion <<<
EOF
    ;;
  zsh)
    cat <<'EOF'
# >>> taskr completion >>>
source <(taskr completion zsh)
# <<< taskr completion <<<
EOF
    ;;
  fish)
    cat <<'EOF'
# >>> taskr completion >>>
taskr completion fish | source
# <<< taskr completion <<<
EOF
    ;;
  *)
    return 1
    ;;
  esac
}

install_completion() {
  local shell rc_path rc_dir
  shell="$(completion_shell)"
  if ! rc_path="$(completion_rc_path)"; then
    echo "completion unsupported shell=${shell:-unknown}"
    return 0
  fi
  rc_dir="$(dirname "${rc_path}")"
  mkdir -p "${rc_dir}"
  touch "${rc_path}"
  if grep -q "# >>> taskr completion >>>" "${rc_path}"; then
    echo "completion already configured shell=${shell} path=${rc_path}"
    return 0
  fi
  {
    printf '\n'
    completion_block
  } >>"${rc_path}"
  echo "completion configured shell=${shell} path=${rc_path}"
}

case "${command}" in
binary)
  output_path="${output_dir}/taskr"
  build_binary "${output_path}"
  persist_version
  echo "built binary path=${output_path} version=${full_version}"
  ;;
deb)
  build_deb
  persist_version
  if [ "${install_deb}" = true ]; then
    install_deb_package
    install_completion
  fi
  ;;
all)
  output_path="${output_dir}/taskr"
  build_binary "${output_path}"
  echo "built binary path=${output_path} version=${full_version}"
  build_deb
  persist_version
  if [ "${install_deb}" = true ]; then
    install_deb_package
    install_completion
  fi
  ;;
install-completion)
  install_completion
  ;;
*)
  fail "unknown command ${command}"
  ;;
esac
