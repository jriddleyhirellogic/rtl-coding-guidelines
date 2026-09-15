#!/usr/bin/env bash
# The frontmatter is the whole triggering mechanism: if name/description are
# malformed the skill silently never fires, which no other check would notice.
set -uo pipefail
. "$REPO_ROOT/tests/lib.sh"

skill_md="$SKILL_DIR/SKILL.md"

check "SKILL.md exists" test -f "$skill_md"
[ -f "$skill_md" ] || finish

check "opens with a --- fence" test "$(head -1 "$skill_md")" = "---"

fm_end=$(awk 'NR>1 && /^---$/ {print NR; exit}' "$skill_md")
if [ -z "$fm_end" ]; then
  fail "frontmatter is closed by a second ---"
  finish
fi
ok "frontmatter is closed by a second ---"

fm=$(sed -n "2,$((fm_end - 1))p" "$skill_md")

name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p')
desc=$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p')

check "frontmatter declares a name" test -n "$name"
check "name matches the directory ($(basename "$SKILL_DIR"))" test "$name" = "$(basename "$SKILL_DIR")"
check "name is a valid slug" grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' <<<"$name"
check "frontmatter declares a description" test -n "$desc"

# Descriptions carry both what the skill does and when to use it; a one-liner
# is almost always too thin to trigger reliably, and a very long one gets
# truncated in the skills list.
check "description is at least 40 chars" test "${#desc}" -ge 40
check "description is at most 1024 chars" test "${#desc}" -le 1024

# Frontmatter keys Claude Code actually reads. An unknown key is usually a typo
# for one of these, so surface it rather than letting it sit inert.
unknown=$(printf '%s\n' "$fm" | grep -oE '^[a-zA-Z_-]+:' | tr -d ':' \
          | grep -vxE 'name|description|license|compatibility|allowed-tools|metadata|version' || true)
if [ -n "$unknown" ]; then
  fail "unrecognized frontmatter keys: $(tr '\n' ' ' <<<"$unknown")"
else
  ok "no unrecognized frontmatter keys"
fi

check "body is non-empty" test "$(sed -n "$((fm_end + 1)),\$p" "$skill_md" | tr -d '[:space:]' | wc -c)" -gt 0

finish
