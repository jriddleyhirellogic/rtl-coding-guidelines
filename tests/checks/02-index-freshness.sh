#!/usr/bin/env bash
# rule-index.md is generated. If someone edits a rule's Message: text or adds
# an NTL_ file without regenerating, the skill reads a stale index and cites
# wrong rules - the worst failure mode this repo has, because it looks right.
set -uo pipefail
. "$REPO_ROOT/tests/lib.sh"

builder="$SKILL_DIR/build-index.sh"
check "build-index.sh exists" test -f "$builder"
check "build-index.sh is executable" test -x "$builder"
[ -x "$builder" ] || finish

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cp "$SKILL_DIR/rule-index.md" "$tmp/committed.md"
"$builder" >/dev/null 2>&1
cp "$SKILL_DIR/rule-index.md" "$tmp/regenerated.md"
cp "$tmp/committed.md" "$SKILL_DIR/rule-index.md"   # leave the tree as we found it

if diff -q "$tmp/committed.md" "$tmp/regenerated.md" >/dev/null; then
  ok "rule-index.md matches build-index.sh output"
else
  fail "rule-index.md is stale - run ./.claude/skills/rtl-coding/build-index.sh"
  diff -u "$tmp/committed.md" "$tmp/regenerated.md" | head -20 | sed 's/^/      /'
fi

finish
