#!/usr/bin/env bash
set -euo pipefail

# Build the current CLI source into Smokey-managed state.
mkdir -p "${SMOKEY_STATE_DIR}/bin"
go build -o "${TASKR_BIN}" ./src/taskr

# Copy committed fixtures into Smokey-managed state for isolated mutation.
mkdir -p "${SMOKEY_STATE_DIR}/fixtures"
cp -R "${SMOKEY_TEST_DIR}/fixtures/base-root" "${TASKR_BASE_ROOT}"
cp -R "${SMOKEY_TEST_DIR}/fixtures/invalid-root" "${TASKR_INVALID_ROOT}"
mkdir -p "${TASKR_EMPTY_ROOT}"

# Report shared fixture doctor problems without turning regular Smokey setup
# into the release-quality data gate.
"${TASKR_BIN}" "${TASKR_BASE_ROOT}" doctor || true

# Write test-only personal config inside Smokey state.
cat >"${TASKR_CONFIG_FILE}" <<EOF
statuses:
  - open
  - designing
  - developing
  - active
  - reviewing
  - blocked
  - done
  - cancelled
editor: "true"
archive_dir: "archive"
EOF
