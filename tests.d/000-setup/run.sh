#!/usr/bin/env bash
set -euo pipefail

# Prepare shared paths for all workflow tests without requiring the CLI to exist yet.
export TASKR_BASE_ROOT="${SMOKEY_STATE_DIR}/fixtures/base-root"
export TASKR_INVALID_ROOT="${SMOKEY_STATE_DIR}/fixtures/invalid-root"
export TASKR_EMPTY_ROOT="${SMOKEY_STATE_DIR}/fixtures/empty-root"
export TASKR_CONFIG_FILE="${SMOKEY_STATE_DIR}/config.yaml"
export TASKR_BIN="${SMOKEY_STATE_DIR}/bin/taskr"

# Build the current CLI source into Smokey-managed state.
mkdir -p "${SMOKEY_STATE_DIR}/bin"
go build -o "${TASKR_BIN}" ./src/taskr

# Copy committed fixtures into Smokey-managed state for isolated mutation.
mkdir -p "${SMOKEY_STATE_DIR}/fixtures"
cp -R "${SMOKEY_TEST_DIR}/fixtures/base-root" "${TASKR_BASE_ROOT}"
cp -R "${SMOKEY_TEST_DIR}/fixtures/invalid-root" "${TASKR_INVALID_ROOT}"
mkdir -p "${TASKR_EMPTY_ROOT}"

# Write test-only personal config inside Smokey state.
cat >"${TASKR_CONFIG_FILE}" <<EOF
statuses:
  - open
  - designing
  - active
  - blocked
  - done
  - cancelled
editor: "true"
archive_dir: "archive"
EOF

# Persist shared values for later tests.
smokey_env_save TASKR_BASE_ROOT
smokey_env_save TASKR_INVALID_ROOT
smokey_env_save TASKR_EMPTY_ROOT
smokey_env_save TASKR_CONFIG_FILE
smokey_env_save TASKR_BIN
