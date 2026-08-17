#!/usr/bin/env bash
set -euo pipefail


# Copy a valid root for archive moves.
root="${SMOKEY_STATE_DIR}/archive-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"

# Closed tasks can be archived below the root archive directory.
run_taskr archive_done "${root}" archive 002 --to 2026
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "archived id=002" "${stdout}"
grep -q "to=archive/2026/002-verzeichnisstruktur" "${stdout}"
test -f "${root}/archive/2026/002-verzeichnisstruktur/task.md"

# The archive location should be inspectable by opting into terminal items.
run_taskr list_archive "${root}" list --all --under archive/2026
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q "002 task done #internal Define directory structure" "${stdout}"

# Active or incomplete subtrees must not be archived.
run_taskr archive_milestone "${root}" archive 001
[ "${exit_code}" -ne 0 ] || { echo "active milestone archive should fail" >&2; exit 1; }
grep -qi "active\\|unfinished\\|closed" "${stderr}"
run_taskr archive_active_task "${root}" archive 003
[ "${exit_code}" -ne 0 ] || { echo "active task archive should fail" >&2; exit 1; }
grep -qi "active\\|unfinished\\|closed" "${stderr}"
