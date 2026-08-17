#!/usr/bin/env bash
set -euo pipefail

version_file="${SMOKEY_STATE_DIR}/VERSION"
build_file="${SMOKEY_STATE_DIR}/BUILD"
output_dir="${SMOKEY_STATE_DIR}/version-bin"

# The default development build should remain explicit.
run_command version_dev "${TASKR_BIN}" version
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "taskr version dev" "${stdout}"

# Release builds should derive SemVer plus monotonic build metadata inside the build script.
printf '0.1.0\n' >"${version_file}"
printf '41\n' >"${build_file}"

run_command build_binary ./scripts/build.sh binary \
  --version-file "${version_file}" \
  --build-file "${build_file}" \
  --output-dir "${output_dir}" \
  --commit abcdef1 \
  --built-at 2026-08-07T09:00:00Z
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "built binary path=${output_dir}/taskr version=0.1.0+42" "${stdout}"
grep -q '^42$' "${build_file}"

run_command version_release "${output_dir}/taskr" version
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "taskr version 0.1.0+42" "${stdout}"
grep -q "commit=abcdef1" "${stdout}"
grep -q "built_at=2026-08-07T09:00:00Z" "${stdout}"

# Minor and major raises reset lower SemVer components but keep the build counter monotonic.
run_command build_raise_minor ./scripts/build.sh binary \
  --version-file "${version_file}" \
  --build-file "${build_file}" \
  --output-dir "${output_dir}" \
  --raise-minor \
  --commit abcdef2 \
  --built-at 2026-08-07T10:00:00Z
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^0.2.0$' "${version_file}"
grep -q '^43$' "${build_file}"
grep -q "version=0.2.0+43" "${stdout}"

run_command build_raise_major ./scripts/build.sh binary \
  --version-file "${version_file}" \
  --build-file "${build_file}" \
  --output-dir "${output_dir}" \
  --raise-major \
  --commit abcdef3 \
  --built-at 2026-08-07T11:00:00Z
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^1.0.0$' "${version_file}"
grep -q '^44$' "${build_file}"
grep -q "version=1.0.0+44" "${stdout}"
