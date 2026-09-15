#!/usr/bin/env bash
# Mechanical test suite for the rtl-coding skill.
#
# Everything here is deterministic and free - no model calls - so it is safe to
# run on every commit and in CI. The behavioral evals live separately; see
# tests/README.md.
#
#   ./tests/run.sh            run every check
#   ./tests/run.sh 02 05      run only the checks whose number matches
#   VERBOSE=1 ./tests/run.sh  also print the checks that passed
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT VERBOSE="${VERBOSE:-}"

checks=()
if [ $# -gt 0 ]; then
  for pat in "$@"; do
    while IFS= read -r f; do checks+=("$f"); done < <(find "$REPO_ROOT/tests/checks" -name "${pat}*.sh" | sort)
  done
else
  while IFS= read -r f; do checks+=("$f"); done < <(find "$REPO_ROOT/tests/checks" -name '*.sh' | sort)
fi

if [ ${#checks[@]} -eq 0 ]; then
  echo "no checks matched" >&2
  exit 1
fi

total_failures=0
for c in "${checks[@]}"; do
  printf '\n%s\n' "$(basename "$c" .sh)"
  bash "$c"
  total_failures=$((total_failures + $?))
done

printf '\n'
if [ "$total_failures" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$total_failures check(s) failed."
fi
exit $(( total_failures > 0 ? 1 : 0 ))
