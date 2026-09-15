#!/usr/bin/env bash
# The index is the skill's map of the corpus. An entry with no file behind it
# sends the skill to a dead path; a file with no entry is invisible to it.
set -uo pipefail
. "$REPO_ROOT/tests/lib.sh"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
corpus_rule_ids > "$tmp/corpus"
index_rule_ids  > "$tmp/index"

check "corpus is non-empty" test -s "$tmp/corpus"
check "index is non-empty"  test -s "$tmp/index"

orphans=$(comm -13 "$tmp/corpus" "$tmp/index")
if [ -n "$orphans" ]; then
  fail "index lists rules with no NTL_*.html file: $(tr '\n' ' ' <<<"$orphans")"
else
  ok "every indexed rule has a file"
fi

missing=$(comm -23 "$tmp/corpus" "$tmp/index")
if [ -n "$missing" ]; then
  fail "rule files missing from the index: $(tr '\n' ' ' <<<"$missing")"
else
  ok "every rule file is indexed"
fi

check "no duplicate index entries" test "$(wc -l < "$tmp/index")" -eq "$(sort -u "$tmp/index" | wc -l)"

# build-index.sh falls back to "(see FILE.html)" when the Message: scrape finds
# nothing. That is a silent scrape failure, not a rule without a message.
stubs=$(grep -c '(see NTL_.*\.html)' "$SKILL_DIR/rule-index.md" || true)
if [ "$stubs" -gt 0 ]; then
  fail "$stubs index entries fell back to '(see ...)' - the Message: scrape failed for them"
  grep -n '(see NTL_.*\.html)' "$SKILL_DIR/rule-index.md" | head -10 | sed 's/^/      /'
else
  ok "no index entry fell back to a '(see ...)' stub"
fi

# Categories the SKILL.md table promises must actually exist in the index,
# otherwise the skill routes a task to a section that is not there.
for cat in CLK CON DFT LAN NAM PAD PAR RST SET STR; do
  check "index has a $cat section" grep -qx "## $cat" "$SKILL_DIR/rule-index.md"
done

finish
