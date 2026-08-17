#!/usr/bin/env bash
set -euo pipefail


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

root="${SMOKEY_STATE_DIR}/comment-root"
cp -R "${TASKR_BASE_ROOT}" "${root}"
marker="${root}/001-mvp/003-workflows-definieren/task.md"

# Help should document selector usage and stdin input.
run_taskr comment_help comment --help
if [ "${exit_code}" -ne 0 ]; then
  echo "comment help should succeed" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q "comment <selector> <text>" "${stdout}"
grep -q -- "--stdin" "${stdout}"

# A single-line comment should append one timestamped entry.
run_taskr comment_single "${root}" comment 003 "Reviewed with Michael"
if [ "${exit_code}" -ne 0 ]; then
  echo "single-line comment should pass" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -q "commented id=003" "${stdout}"
grep -Eq '^- [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}: Reviewed with Michael$' "${marker}"

# Quotes should be preserved and repeated spaces or tabs should normalize.
quoted_comment=$'  Michael\'s   "quoted"\t note  '
run_taskr comment_quotes "${root}" comment 003 "${quoted_comment}"
if [ "${exit_code}" -ne 0 ]; then
  echo "quoted comment should pass" >&2
  cat "${stderr}" >&2
  exit 1
fi
grep -Eq "^- [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}: Michael's \"quoted\" note$" "${marker}"

# A heredoc through stdin should append one multi-line comment entry.
"${TASKR_BIN}" "${root}" comment 003 --stdin >"${SMOKEY_STATE_DIR}/comment_stdin.stdout" 2>"${SMOKEY_STATE_DIR}/comment_stdin.stderr" <<'EOF'
  first   detail

second	detail
EOF
grep -q "commented id=003" "${SMOKEY_STATE_DIR}/comment_stdin.stdout"
grep -Eq '^- [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:$' "${marker}"
grep -q '^  first detail$' "${marker}"
grep -q '^  second detail$' "${marker}"
if grep -q '^  $' "${marker}"; then
  echo "empty stdin lines should not be stored" >&2
  exit 1
fi

# Comments must be inserted before Outcome while preserving required sections.
comments_line="$(grep -n '^# Comments$' "${marker}" | cut -d: -f1)"
outcome_line="$(grep -n '^# Outcome$' "${marker}" | cut -d: -f1)"
review_line="$(grep -n 'Reviewed with Michael' "${marker}" | cut -d: -f1)"
detail_line="$(grep -n '^  second detail$' "${marker}" | cut -d: -f1)"
[ "${comments_line}" -lt "${review_line}" ]
[ "${review_line}" -lt "${detail_line}" ]
[ "${detail_line}" -lt "${outcome_line}" ]

# Ambiguous selectors and invalid input combinations should fail without edits.
before_hash="$(sha256sum "${marker}" | cut -d' ' -f1)"
cp -R "${TASKR_BASE_ROOT}" "${SMOKEY_STATE_DIR}/comment-ambiguous-root"
ambiguous_root="${SMOKEY_STATE_DIR}/comment-ambiguous-root"
mkdir -p "${ambiguous_root}/001-mvp/006-workflows-review"
cp "${ambiguous_root}/001-mvp/003-workflows-definieren/task.md" "${ambiguous_root}/001-mvp/006-workflows-review/task.md"
run_taskr comment_ambiguous "${ambiguous_root}" comment workflows "Ambiguous"
if [ "${exit_code}" -eq 0 ]; then
  echo "ambiguous comment selector should fail" >&2
  exit 1
fi
grep -qi "ambiguous\\|candidates" "${stderr}"

run_taskr comment_missing_text "${root}" comment 003
if [ "${exit_code}" -eq 0 ]; then
  echo "comment without text should fail" >&2
  exit 1
fi
grep -qi "text\\|stdin" "${stderr}"

run_taskr comment_stdin_with_text "${root}" comment 003 --stdin "extra text"
if [ "${exit_code}" -eq 0 ]; then
  echo "comment should reject --stdin with text arguments" >&2
  exit 1
fi
grep -qi "stdin\\|text" "${stderr}"
after_hash="$(sha256sum "${marker}" | cut -d' ' -f1)"
[ "${before_hash}" = "${after_hash}" ]
