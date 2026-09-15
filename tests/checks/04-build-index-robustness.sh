#!/usr/bin/env bash
# build-index.sh runs against a corpus that changes. These checks pin the
# properties that make its output trustworthy: stable ordering (so a rebuild
# is a clean diff, not a reshuffle) and correct path resolution from anywhere.
set -uo pipefail
. "$REPO_ROOT/tests/lib.sh"

builder="$SKILL_DIR/build-index.sh"
[ -x "$builder" ] || { fail "build-index.sh missing or not executable"; finish; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp "$SKILL_DIR/rule-index.md" "$tmp/original.md"
restore() { cp "$tmp/original.md" "$SKILL_DIR/rule-index.md"; }

# Deterministic: two runs in a row must agree. `ls | sort -V` is locale- and
# glob-order-sensitive, so this is a real risk, not a formality.
"$builder" >/dev/null 2>&1; cp "$SKILL_DIR/rule-index.md" "$tmp/run1.md"
"$builder" >/dev/null 2>&1; cp "$SKILL_DIR/rule-index.md" "$tmp/run2.md"
check "two consecutive builds produce identical output" diff -q "$tmp/run1.md" "$tmp/run2.md"

# Locale-independent: sorting under a different collation must not reorder.
LC_ALL=C "$builder" >/dev/null 2>&1; cp "$SKILL_DIR/rule-index.md" "$tmp/c.md"
LC_ALL=en_US.UTF-8 "$builder" >/dev/null 2>&1; cp "$SKILL_DIR/rule-index.md" "$tmp/utf8.md"
check "output is stable across locales" diff -q "$tmp/c.md" "$tmp/utf8.md"

# Callable from anywhere: the script resolves the repo root from BASH_SOURCE,
# so it must not depend on the caller's cwd.
(cd / && "$builder" >/dev/null 2>&1)
cp "$SKILL_DIR/rule-index.md" "$tmp/from-root.md"
check "produces the same output when invoked from another directory" \
  diff -q "$tmp/run1.md" "$tmp/from-root.md"

# Natural ordering within a section: STR9 must precede STR100, not follow it.
str_order=$(sed -n '/^## STR/,/^## /p' "$SKILL_DIR/rule-index.md" \
            | grep -oE 'NTL_STR[0-9]+' | sed 's/NTL_STR//')
if [ "$str_order" = "$(sort -n <<<"$str_order")" ]; then
  ok "STR entries are in numeric order"
else
  fail "STR entries are not in numeric order (sort -V regression?)"
fi

restore
finish
