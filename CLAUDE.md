# RTL Coding Guidelines

This repo is a reference corpus of RTL (Verilog / SystemVerilog / VHDL) coding rules:

- the Synopsys Leda `NTL_*` rules plus several long policy/style documents (`pol_*.html`), and
- supplementary check families under `.claude/skills/rtl-coding/checks/` covering auto-formal,
  formal-app, DO-254 and modern-lint checks that Leda does not.

## Don't read every file

There are 264 `NTL_*` rule files and 18 long policy documents. Do **not** load them all into
context. Use the skill below — it knows how to look up only what's relevant to the current task.

## How to use these guidelines

A Claude Code skill named **`rtl-coding`** ships with this repo at `.claude/skills/rtl-coding/SKILL.md`. It has its own indexed view of the rules and tells Claude how to apply them when generating, reviewing, or refactoring RTL.

The skill is invoked automatically when the task matches (RTL generation, RTL review, questions about a rule ID, CDC/DFT/clock/reset questions, etc.). You can also invoke it explicitly with `/rtl-coding` once installed.

### Installing the skill globally

To make the skill available in any project on your machine:

```bash
mkdir -p ~/.claude/skills
ln -s "$(pwd)/.claude/skills/rtl-coding" ~/.claude/skills/rtl-coding
```

Or copy it (less ideal — won't track updates):

```bash
cp -r .claude/skills/rtl-coding ~/.claude/skills/
```

### Regenerating the rule index

`rule-index.md` is generated from the `NTL_*.html` files and the `checks/*.md` files. Regenerate it
after adding or editing either:

```bash
./.claude/skills/rtl-coding/build-index.sh
```

## Tests

`./tests/run.sh` is the free, deterministic suite — it checks that `rule-index.md`
is in sync with the corpus, that `SKILL.md` only cites files and rule IDs that
exist, and that the eval cases are valid. Run it after touching a rule file, the
index, or the skill.

The behavioral suite (`claude plugin eval .claude/skills/rtl-coding`) costs model
calls and is for before you release a skill change. Both are documented in
`tests/README.md`.

## Rule categories

| Code | Topic |
|------|-------|
| CLK  | Clocks, gating, edges, domains |
| RST  | Reset style, sync vs async, polarity |
| CON  | Connectivity — ports, nets, tie-offs, unconnected pins |
| DFT  | Design for test |
| LAN  | Language legality / portability |
| NAM  | Naming conventions |
| PAD  | Pad cells / chip I/O |
| PAR  | Hierarchy / partitioning |
| SET  | Set-domain rules (async set) |
| STR  | Structural / style rules (largest category) |

The Leda rules are **structural**: connectivity, gate topology, clock/reset tree shape, scan
structure. They say nothing about behaviour over time or about design assurance process.

## Supplementary check families

Markdown, under `.claude/skills/rtl-coding/checks/`. These cover the gaps in `NTL_*`:

| Prefix | File | Topic |
|--------|------|-------|
| `AF_` | `auto-formal.md` | Auto-formal checks needing no testbench — FSM deadlock/livelock/reachability, arithmetic overflow, out-of-bounds indexing, dead code, X assignment, `case` conformance. Siemens **Questa Inspect** (formerly Questa AutoCheck) and Cadence **Jasper Superlint**. |
| `FA_` | `formal-apps.md` | RTL requirements imposed by targeted formal apps — CDC/RDC, X-propagation, sequential equivalence, connectivity, CSR, functional safety, security path, coverage unreachability. |
| `DO_` | `do254.md` | RTCA/DO-254 airborne electronic hardware design assurance, DAL-driven — latch and tri-state prohibition, safe FSM, reset discipline, traceability, elemental analysis, tool qualification. |
| `ML_` | `modern-lint.md` | Checks a current SystemVerilog flow adds over Leda — width and sign mismatch, sensitivity lists, blocking/non-blocking, implicit nets, `casex`. Synopsys VC SpyGlass, Verilator, Verible, svlint. |

IDs in these files are **ours**, not the vendors'. Tool check names and switches vary by release;
each entry names the tool check conceptually so you can find it in that tool's rule browser, but
don't paste them as literal rule names without confirming against your installed version. See
`checks/README.md` for the ID scheme and entry format.

Note that `DO_*` is stricter than commercial practice and in places conflicts with the other
families (defensive FSM branches that auto-formal will correctly report as unreachable, for
instance). `SKILL.md` has a conflicts table. Apply `DO_*` only to safety-critical work.

Long-form policy documents are the `pol_*.html` files; consult them only when a task requires that depth.
