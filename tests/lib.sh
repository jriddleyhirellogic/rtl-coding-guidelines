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

# Resolve a rule ID to its definition. NTL_* rules are one file each in the
# repo root; the supplementary families (AF_*, DO_*, ML_*, FA_*) are defined
# inside the skill's checks/*.md docs. Returns 0 if the ID is defined anywhere.
rule_is_defined() {
  local id="$1"
  [ -f "$REPO_ROOT/$id.html" ] && return 0
  grep -rqF "$id" "$SKILL_DIR/checks" 2>/dev/null && return 0
  return 1
}

# Is the rule discoverable from the index the skill actually reads?
rule_is_indexed() {
  local id="$1"
  grep -qF "\`$id\`" "$SKILL_DIR/rule-index.md" 2>/dev/null && return 0
  grep -rqF "$id" "$SKILL_DIR/checks" 2>/dev/null && return 0
  return 1
}
