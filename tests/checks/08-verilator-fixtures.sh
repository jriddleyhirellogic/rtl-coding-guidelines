#!/usr/bin/env bash
# Lint the golden fixtures with a real Verilog front end.
#
# This is an independent source of truth on what each fixture actually
# contains. The .expect files are hand-written claims; Verilator either agrees
# or it does not, and it costs nothing to ask.
#
# Its reach is narrow and worth stating plainly: Verilator has no CDC analysis
# and no clock-tree structural checks, so cdc_missing_sync.v and
# gated_clock_div.v lint completely clean despite both being defective. Those
# defects are the behavioral suite's job. What Verilator does cover here is
# that every fixture still elaborates, that the clean control stays clean, and
# that the defects it can see have not silently evaporated from a fixture edit.
set -uo pipefail
. "$REPO_ROOT/tests/lib.sh"

if ! command -v verilator >/dev/null 2>&1; then
  printf '    SKIP verilator not installed (apt-get install verilator)\n'
  printf '  0 passed, 0 failed (skipped)\n'
  exit 0
fi

# DECLFILENAME fires because fixtures are named for the defect, not the module.
# That is deliberate, so silence it rather than renaming every fixture.
VFLAGS=(--lint-only -Wall -Wno-fatal -Wno-DECLFILENAME)

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

for fx in $(golden_fixtures); do
  rtl="$GOLDEN_DIR/rtl/$fx.v"
  exp="$GOLDEN_DIR/expected/$fx.expect"

  # Fixtures carry //! annotations, which are ordinary comments to Verilator,
  # so they need no stripping here.
  verilator "${VFLAGS[@]}" "$rtl" >"$tmp/$fx.out" 2>&1
  codes=$(grep -oE '%(Warning-[A-Z]+|Error[-A-Z]*)' "$tmp/$fx.out" | sort -u | tr '\n' ' ')

  # Elaboration is non-negotiable: a fixture that does not parse tests nothing.
  if grep -q '%Error' "$tmp/$fx.out"; then
    fail "$fx.v elaborates"
    sed -n '1,6p' "$tmp/$fx.out" | sed 's/^/      /'
  else
    ok "$fx.v elaborates"
  fi

  must=$(expect_field "$exp" must_flag)

  # The clean control has to be clean by an independent reckoning too. A
  # control carrying real defects punishes the skill for finding them - which
  # is exactly how the first behavioral pass went wrong.
  if [ -z "$must" ]; then
    if [ -z "$codes" ]; then
      ok "$fx.v is Verilator-clean (false-positive control)"
    else
      fail "$fx.v is the clean control but Verilator reports: $codes"
      grep -E '^%' "$tmp/$fx.out" | head -5 | sed 's/^/      /'
    fi
  fi

  # Optional per-fixture assertion, for defects Verilator can actually see.
  want=$(expect_field "$exp" verilator_expect)
  for code in $want; do
    if grep -q "%Warning-$code\|%Error-$code" "$tmp/$fx.out"; then
      ok "$fx.v still trips $code"
    else
      fail "$fx.v no longer trips $code (found: ${codes:-nothing})"
    fi
  done
done

finish
