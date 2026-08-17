#!/usr/bin/env bash
set -euo pipefail

TASKR_BIN="${TASKR_BIN:-${SMOKEY_STATE_DIR}/bin/taskr}"
TASKR_BASE_ROOT="${TASKR_BASE_ROOT:-${SMOKEY_STATE_DIR}/fixtures/base-root}"

run_taskr() {
  local name="$1"
  shift
  stdout="${SMOKEY_STATE_DIR}/${name}.stdout"
  stderr="${SMOKEY_STATE_DIR}/${name}.stderr"
  set +e
  "${TASKR_BIN}" "$@" >"${stdout}" 2>"${stderr}"
  exit_code=$?
  set -e
}

# Prepare one valid root with distinct text in every searchable marker section.
root="${SMOKEY_STATE_DIR}/list-glob-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
marker="${root}/001-mvp/003-workflows-definieren/task.md"
sed -i '/# Acceptance/i DescriptionOnly AlphaNeedle appears here.\n' "${marker}"
sed -i '/# Comments/i - AcceptanceOnly BetaNeedle is required.\n' "${marker}"
sed -i '/# Outcome/i - CommentsOnly GammaNeedle was discussed.\n' "${marker}"
printf '\nOutcomeOnly DeltaNeedle was delivered.\n' >>"${marker}"

# Unadorned patterns match marker-line substrings without explicit stars.
run_taskr glob_substring "${root}" list --glob phaneed
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 task active #(release,website) Define workflows$' "${stdout}"
[ "$(wc -l <"${stdout}")" -eq 1 ]

# Matching is case-insensitive and includes frontmatter fields.
run_taskr glob_case_title "${root}" list --glob 'TITLE: DEFINE WORKFLOWS'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 ' "${stdout}"
run_taskr glob_frontmatter_status "${root}" list --glob 'STATUS: ACTIVE'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^001 ' "${stdout}"
grep -q '^003 ' "${stdout}"
grep -q '^005 ' "${stdout}"

# Full-text matching covers Acceptance, Comments, and Outcome.
for pair in acceptance:BetaNeedle comments:GammaNeedle outcome:DeltaNeedle; do
  name="${pair%%:*}"
  pattern="${pair#*:}"
  run_taskr "glob_${name}" "${root}" list --glob "${pattern}"
  [ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
  grep -q '^003 ' "${stdout}"
  [ "$(wc -l <"${stdout}")" -eq 1 ]
done

# Star, question mark, character classes, and ranges use glob semantics.
run_taskr glob_star "${root}" list --glob 'Alpha*here.'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 ' "${stdout}"
run_taskr glob_question "${root}" list --glob 'BetaNeedl?'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 ' "${stdout}"
run_taskr glob_class "${root}" list --glob 'GammaNeedl[eE]'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 ' "${stdout}"
run_taskr glob_range "${root}" list --glob 'DeltaNeedl[a-z]'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 ' "${stdout}"

# Repeated globs form an AND expression and may match different lines.
run_taskr glob_and "${root}" list --glob AlphaNeedle --glob DeltaNeedle
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 ' "${stdout}"
[ "$(wc -l <"${stdout}")" -eq 1 ]
run_taskr glob_and_no_match "${root}" list --glob AlphaNeedle --glob RootNeedleAbsent
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ ! -s "${stdout}" ]

# One glob cannot span adjacent marker lines.
cat >>"${marker}" <<'EOF'
CrossLineStart
CrossLineEnd
EOF
run_taskr glob_no_newline "${root}" list --glob 'CrossLineStart*CrossLineEnd'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ ! -s "${stdout}" ]
run_taskr glob_separate_lines "${root}" list --glob CrossLineStart --glob CrossLineEnd
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 ' "${stdout}"

# Glob composes with type, status, priority, under, and unfinished defaults.
run_taskr glob_combined "${root}" list --type task --status active --priority normal --under 001 --glob AlphaNeedle
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^003 ' "${stdout}"
[ "$(wc -l <"${stdout}")" -eq 1 ]
run_taskr glob_closed_default "${root}" list --glob 'Done task used'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ ! -s "${stdout}" ]
run_taskr glob_closed_all "${root}" list --all --glob 'Done task used'
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q '^002 ' "${stdout}"

# No matches succeed with empty output; malformed patterns fail as usage errors.
run_taskr glob_empty "${root}" list --glob DefinitelyAbsent
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ ! -s "${stdout}" ]
run_taskr glob_malformed "${root}" list --glob '[unterminated'
[ "${exit_code}" -eq 2 ] || { echo "malformed glob should exit 2" >&2; exit 1; }
grep -qi 'invalid.*glob\|glob.*invalid\|malformed' "${stderr}"

# Attachments below files.md containers are outside marker full-text search.
printf 'AttachmentOnly EpsilonNeedle\n' >"${root}/files/attachment.txt"
run_taskr glob_attachment "${root}" list --glob EpsilonNeedle
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
[ ! -s "${stdout}" ]

# Help, examples, and completion expose the full-text glob filter.
run_taskr glob_help list --help
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q -- '--glob string' "${stdout}"
grep -qi 'full.*marker\|marker.*text' "${stdout}"
run_taskr glob_examples examples
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -Fq 'taskr list --glob workflow' "${stdout}"
grep -Fq "taskr list --all --type task --under 001 --glob 'release*' --glob artifact" "${stdout}"
run_taskr glob_completion __complete list --glob ''
[ "${exit_code}" -eq 0 ] || { cat "${stderr}" >&2; exit 1; }
grep -q ':0$' "${stdout}"
