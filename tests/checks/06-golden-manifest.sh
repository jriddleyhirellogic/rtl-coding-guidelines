#!/usr/bin/env bash
# The golden fixtures are only as good as the rule IDs they expect. A typo in
# a .expect file makes the behavioral eval unpassable for a reason that has
# nothing to do with the skill, so validate the manifest without a model.
set -uo pipefail
. "$REPO_ROOT/tests/lib.sh"

fixtures=$(golden_fixtures)
check "at least one golden fixture exists" test -n "$fixtures"

saw_clean=0
for fx in $fixtures; do
  rtl="$GOLDEN_DIR/rtl/$fx.v"
  exp="$GOLDEN_DIR/expected/$fx.expect"

  if [ ! -f "$exp" ]; then
    fail "$fx.v has no matching expected/$fx.expect"
    continue
  fi
  ok "$fx has an expectation file"

  summary=$(expect_field "$exp" summary)
  check "$fx declares a summary" test -n "$summary"

  must=$(expect_field "$exp" must_flag)
  mustnt=$(expect_field "$exp" must_not_flag)

  [ -z "$must" ] && saw_clean=1

  for id in $must $mustnt; do
    check "$fx expects a real rule $id" test -f "$REPO_ROOT/$id.html"
    check "$fx's $id is in the index" grep -qF "\`$id\`" "$SKILL_DIR/rule-index.md"
  done

  # A rule cannot be both required and forbidden in the same review.
  overlap=$(comm -12 <(tr ' ' '\n' <<<"$must" | sort -u) <(tr ' ' '\n' <<<"$mustnt" | sort -u) | grep -v '^$' || true)
  if [ -n "$overlap" ]; then
    fail "$fx lists $overlap in both must_flag and must_not_flag"
  else
    ok "$fx has no contradictory expectations"
  fi

  check "$fx.v declares a module" grep -qE '^\s*module\s' "$rtl"
  check "$fx.v is terminated by endmodule" grep -qE '^\s*endmodule' "$rtl"
done

# Without a clean fixture the suite only ever rewards flagging things, and a
# skill that flags everything would score perfectly.
if [ "$saw_clean" -eq 1 ]; then
  ok "suite includes a clean false-positive control"
else
  fail "no fixture with an empty must_flag - add a clean control"
fi

finish
