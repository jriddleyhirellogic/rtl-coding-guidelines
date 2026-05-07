#!/usr/bin/env bash
# Regenerate rule-index.md from the NTL_*.html files in the repo root.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../../.." && pwd)"
out="$script_dir/rule-index.md"

cd "$repo_root"

{
  echo "# RTL Coding Rule Index"
  echo ""
  echo "Auto-generated index of all NTL_* rules. Each entry: \`RULE_ID\` — message."
  echo "Read the corresponding \`<RULE_ID>.html\` for full description, severity, examples, and policy."
  echo ""
  for category in CLK CON DFT LAN NAM PAD PAR RST SET STR; do
    echo "## $category"
    echo ""
    for f in $(ls NTL_${category}*.html 2>/dev/null | sort -V); do
      id="${f%.html}"
      msg=$(grep -a -oP 'Message:\s*[^<]+' "$f" | head -1 | sed -e 's/^Message:\s*//' -e 's/\s*$//')
      [ -z "$msg" ] && msg="(see $f)"
      echo "- \`$id\` — $msg"
    done
    echo ""
  done
} > "$out"

echo "Wrote $out ($(wc -l < "$out") lines)"
