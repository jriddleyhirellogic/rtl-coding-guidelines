#!/usr/bin/env bash
# SKILL.md names specific files and rule IDs. Every one of those is a promise
# the corpus has to keep - a broken reference sends the skill reading a path
# that does not exist, and it has no way to tell that from an empty rule.
set -uo pipefail
. "$REPO_ROOT/tests/lib.sh"

skill_md="$SKILL_DIR/SKILL.md"

# pol_*.html files named in the skill body
while read -r pol; do
  [ -z "$pol" ] && continue
  check "SKILL.md references an existing $pol" test -f "$REPO_ROOT/$pol"
done < <(grep -oE 'pol_[a-z_]+\.html' "$skill_md" | sort -u)

# Concrete rule IDs cited in the skill body (NTL_CLK05, and bare CLK05 forms)
while read -r id; do
  [ -z "$id" ] && continue
  check "SKILL.md cites an existing rule $id" test -f "$REPO_ROOT/$id.html"
done < <(grep -oE 'NTL_[A-Z]{3}[0-9]+[A-Z]?' "$skill_md" | sort -u)

while read -r short; do
  [ -z "$short" ] && continue
  check "SKILL.md cites an existing rule NTL_$short" test -f "$REPO_ROOT/NTL_$short.html"
done < <(grep -oE '`(CLK|CON|DFT|LAN|NAM|PAD|PAR|RST|SET|STR)[0-9]+[A-Z]?`' "$skill_md" \
         | tr -d '`' | sort -u)

# Reference docs the skill body routes to (checks/*.md and friends). These are
# progressive-disclosure targets: the skill only reads one when a task needs it,
# so a broken path fails rarely and confusingly rather than loudly.
while read -r ref; do
  [ -z "$ref" ] && continue
  check "SKILL.md references an existing $ref" test -f "$SKILL_DIR/$ref"
done < <(grep -oE '\b(checks|references|scripts|assets)/[A-Za-z0-9._-]+\.[a-z]+' "$skill_md" | sort -u)

# Rule IDs from the supplementary check families (AF_*, DO_*, ML_*, ...) are
# defined in those docs rather than in NTL_*.html, so resolve them there.
while read -r id; do
  [ -z "$id" ] && continue
  if grep -rqF "$id" "$SKILL_DIR/checks" "$SKILL_DIR/rule-index.md" 2>/dev/null; then
    ok "SKILL.md cites a defined rule $id"
  else
    fail "SKILL.md cites $id, which is defined nowhere in the skill"
  fi
done < <(grep -oE '\b(AF|DO|ML|FA)_[A-Z0-9]+\b' "$skill_md" | sort -u)

# Files the skill's own directory must contain
for f in rule-index.md build-index.sh; do
  check "skill ships $f" test -f "$SKILL_DIR/$f"
done

# CLAUDE.md points people at the skill and the builder; keep those honest too.
if [ -f "$REPO_ROOT/CLAUDE.md" ]; then
  check "CLAUDE.md's skill path resolves" test -f "$REPO_ROOT/.claude/skills/rtl-coding/SKILL.md"
  check "CLAUDE.md's build-index path resolves" test -x "$REPO_ROOT/.claude/skills/rtl-coding/build-index.sh"
fi

finish
