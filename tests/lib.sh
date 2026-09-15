# Shared helpers for the mechanical test suite. Sourced, not executed.
#
# Each check script sources this, calls ok/fail as it goes, and ends with
# finish. Exit status is the number of failures, so run.sh can just sum them.

: "${REPO_ROOT:?REPO_ROOT must be set before sourcing lib.sh}"
SKILL_DIR="$REPO_ROOT/.claude/skills/rtl-coding"
GOLDEN_DIR="$REPO_ROOT/tests/golden"

_pass=0
_fail=0

ok()   { _pass=$((_pass + 1)); [ -n "${VERBOSE:-}" ] && printf '    ok   %s\n' "$1"; return 0; }
fail() { _fail=$((_fail + 1)); printf '    FAIL %s\n' "$1"; return 0; }

# check <description> <condition-exit-status-command...>
check() {
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else fail "$desc"; fi
}

finish() {
  printf '  %d passed, %d failed\n' "$_pass" "$_fail"
  exit "$_fail"
}

# Every rule ID mentioned anywhere in the corpus, one per line.
corpus_rule_ids() {
  find "$REPO_ROOT" -maxdepth 1 -name 'NTL_*.html' -printf '%f\n' | sed 's/\.html$//' | sort
}

# Every rule ID listed in rule-index.md, one per line.
index_rule_ids() {
  sed -n 's/^- `\(NTL_[A-Z0-9]*\)`.*/\1/p' "$SKILL_DIR/rule-index.md" | sort
}

# Read one field from a .expect file: expect_field <file> <key>
expect_field() {
  sed -n "s/^$2:[[:space:]]*//p" "$1" | head -1
}

golden_fixtures() {
  find "$GOLDEN_DIR/rtl" -name '*.v' -printf '%f\n' | sed 's/\.v$//' | sort
}
