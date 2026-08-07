#!/usr/bin/env bash
set -euo pipefail

output_dir="${SMOKEY_STATE_DIR}/dist"
work_dir="${SMOKEY_STATE_DIR}/work"
version_file="${SMOKEY_STATE_DIR}/VERSION"
build_file="${SMOKEY_STATE_DIR}/BUILD"
stdout="${SMOKEY_STATE_DIR}/build_deb.stdout"
stderr="${SMOKEY_STATE_DIR}/build_deb.stderr"

printf '0.1.0\n' >"${version_file}"
printf '41\n' >"${build_file}"

set +e
./scripts/build.sh deb \
  --version-file "${version_file}" \
  --build-file "${build_file}" \
  --work-dir "${work_dir}" \
  --output-dir "${output_dir}" >"${stdout}" 2>"${stderr}"
exit_code=$?
set -e

[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "built package path=" "${stdout}"
grep -q "version=0.1.0+42-1" "${stdout}"
grep -q '^42$' "${build_file}"

package="${output_dir}/taskr_0.1.0+42-1_amd64.deb"
test -f "${package}"

dpkg-deb --field "${package}" Package | grep -q '^taskr$'
dpkg-deb --field "${package}" Version | grep -q '^0.1.0+42-1$'
dpkg-deb --field "${package}" Architecture | grep -q '^amd64$'
dpkg-deb --contents "${package}" | grep -q '/usr/bin/taskr$'
