#!/usr/bin/env bash
# Validate the eval suite without spending a single model call. A case.yaml
# that fails schema validation only surfaces when someone runs the (slow, paid)
# eval, which is exactly when they least want to debug YAML.
set -uo pipefail
. "$REPO_ROOT/tests/lib.sh"

EVALS_DIR="$SKILL_DIR/evals"
check "evals directory exists" test -d "$EVALS_DIR"
[ -d "$EVALS_DIR" ] || finish

cases=$(find "$EVALS_DIR" -mindepth 2 -maxdepth 2 -name case.yaml | sort)
check "at least one eval case exists" test -n "$cases"

if ! python3 -c 'import yaml' 2>/dev/null; then
  fail "python3 with PyYAML is required to validate eval cases"
  finish
fi

for c in $cases; do
  name=$(basename "$(dirname "$c")")
  out=$(CASE_FILE="$c" python3 "$REPO_ROOT/tests/validate_case.py" 2>&1)
  if [ $? -eq 0 ]; then
    ok "$name/case.yaml is valid"
  else
    fail "$name/case.yaml is invalid"
    sed 's/^/      /' <<<"$out"
  fi
done

# Generated review cases must match the fixtures, same freshness contract as
# rule-index.md. Regenerate into a scratch copy and diff.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp -r "$EVALS_DIR" "$tmp/before"
"$REPO_ROOT/tests/gen-eval-cases.sh" >/dev/null 2>&1
cp -r "$EVALS_DIR" "$tmp/after"

if diff -r "$tmp/before" "$tmp/after" >/dev/null 2>&1; then
  ok "generated review cases are up to date with tests/golden/"
else
  fail "generated review cases are stale - run ./tests/gen-eval-cases.sh"
  diff -r "$tmp/before" "$tmp/after" 2>&1 | head -20 | sed 's/^/      /'
fi

# The planted-defect annotations must never reach a prompt.
leaked=$(grep -rl '//!' "$EVALS_DIR" 2>/dev/null || true)
if [ -n "$leaked" ]; then
  fail "fixture annotations leaked into eval prompts: $(tr '\n' ' ' <<<"$leaked")"
else
  ok "no fixture annotations leaked into eval prompts"
fi

# Every rule ID a grader asserts on must be a real rule.
while read -r id; do
  [ -z "$id" ] && continue
  check "grader pattern cites an existing rule $id" test -f "$REPO_ROOT/$id.html"
done < <(grep -rhoE 'NTL_[A-Z]{3}[0-9]+[A-Z]?' "$EVALS_DIR" --include=case.yaml | sort -u)

finish
