#!/usr/bin/env bash
# Regenerate rule-index.md from the NTL_*.html files in the repo root and the
# supplementary check families in checks/*.md.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../../.." && pwd)"
out="$script_dir/rule-index.md"

cd "$repo_root"

{
  echo "# RTL Coding Rule Index"
  echo ""
  echo "Auto-generated. Do not edit by hand — run \`build-index.sh\`."
  echo ""
  echo "Two corpora are indexed here:"
  echo ""
  echo "1. **\`NTL_*\`** — Synopsys Leda structural/netlist lint. Each entry: \`RULE_ID\` — message."
  echo "   Read the corresponding \`<RULE_ID>.html\` in the repo root for full description,"
  echo "   severity, examples, and policy."
  echo "2. **\`AF_*\` / \`FA_*\` / \`DO_*\` / \`ML_*\`** — supplementary check families covering"
  echo "   auto-formal, formal apps, DO-254 and modern lint. Read the corresponding file under"
  echo "   \`checks/\` for details. See \`checks/README.md\` for what each prefix means."
  echo ""
  echo "---"
  echo ""
  echo "# Leda rules (\`NTL_*\`)"
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

  echo "---"
  echo ""
  echo "# Supplementary checks"
  echo ""

  # Each checks/*.md uses "### \`ID\` — title" for every check entry.
  for f in "$script_dir"/checks/*.md; do
    base="$(basename "$f")"
    [ "$base" = "README.md" ] && continue
    # First H1 in the file is the section title.
    title=$(grep -m1 '^# ' "$f" | sed -e 's/^# //')
    echo "## ${title:-$base}"
    echo ""
    echo "Source: \`checks/$base\`"
    echo ""
    sed -n 's/^### `\([A-Z0-9_]*\)` — \(.*\)$/- `\1` — \2/p' "$f"
    echo ""
  done
} > "$out"

n_ntl=$(grep -c '^- `NTL_' "$out" || true)
n_sup=$(grep -cE '^- `(AF|FA|DO|ML)_' "$out" || true)
echo "Wrote $out ($(wc -l < "$out") lines; $n_ntl Leda rules, $n_sup supplementary checks)"
