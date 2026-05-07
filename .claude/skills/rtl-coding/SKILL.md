---
name: rtl-coding
description: Generate, review, or refactor RTL code (Verilog, SystemVerilog, VHDL) following the Synopsys Leda / RMM coding guidelines bundled with this skill. Use when the user asks to write, modify, or review RTL — module/entity definitions, FSMs, clock/reset logic, FIFOs, synchronizers, pads, parameterized blocks, testbenches that interact with DUT RTL — or when reviewing RTL for lint/CDC/DFT issues. Also use when the user asks about a specific rule ID like `NTL_CLK01` or about clock-domain-crossing, reset, naming, partitioning, structure, or DFT conventions.
---

# RTL Coding Guidelines Skill

This skill applies a curated set of RTL coding rules (the NTL_* rules, plus several policy documents) when generating or reviewing Verilog, SystemVerilog, and VHDL.

## Rule corpus location

The rule files live in the repository this skill ships from:

```
<RULES_ROOT>/
  rule-index.md              # one-line summary of every NTL_* rule, by category
  NTL_<CAT><NN>.html         # individual rule details (description, severity, examples)
  pol_*.html                 # large policy documents (style guides, CDC, DFT, etc.)
```

`<RULES_ROOT>` is the directory three levels above this `SKILL.md` (i.e. the repo root: `<repo>/.claude/skills/rtl-coding/SKILL.md` → `<repo>`). The skill is designed to be installed as a symlink from `~/.claude/skills/rtl-coding` → `<repo>/.claude/skills/rtl-coding`, so relative paths from this file resolve correctly.

If invoked from outside the repo, ask the user for the path to the rule corpus before proceeding.

## Workflow

When asked to **generate** RTL:

1. **Identify scope.** What is the block? (FSM, FIFO, sync, arbiter, pad, top-level glue, …) What language? What clock/reset structure?
2. **Pick relevant rule categories** — do not load every rule. Use this mapping:
   - Always: `NAM` (naming), `STR` (structure/coding style), `LAN` (language).
   - Anything sequential: `CLK`, `RST`.
   - Multi-clock or async inputs: `CLK05`, `CLK04`, plus `pol_cdc.html`.
   - Test/scan: `DFT`.
   - I/O cells: `PAD`.
   - Hierarchy / module partitioning: `PAR`.
   - Synthesis constraints / setup: `SET`, plus `pol_constraints.html` if asked.
3. **Read `rule-index.md`** to find specific rule IDs that apply. Read individual `NTL_<ID>.html` files only for rules whose one-line message is ambiguous or whose example you need.
4. **Write the RTL.** Conform to every rule whose category you selected. Inline a comment with the rule ID only when a non-obvious choice is being made because of a rule (e.g. `// NTL_CLK05: double-flop synchronizer`).
5. **Self-check.** Before returning, scan the generated code against the relevant category in `rule-index.md` and fix violations.

When asked to **review** existing RTL:

1. Read the file(s).
2. Walk through each category in `rule-index.md` that applies (typically NAM, STR, LAN, CLK, RST, plus DFT if scan is in scope).
3. For each likely violation, read the matching `NTL_<ID>.html` to confirm and quote the rule.
4. Report findings as a list: `RULE_ID — file:line — what's wrong — suggested fix`.

When asked **about a specific rule** (e.g. "what does NTL_CLK05 mean?"):

1. Read `NTL_<ID>.html` directly.
2. Summarize: message, severity, language scope, why it matters, and one good/bad code example from the file.

## Categories at a glance

| Code | Topic | When to consult |
|------|-------|-----------------|
| CLK  | Clocks, gating, edges, domains | Any sequential logic |
| RST  | Reset style, sync vs async, polarity | Any sequential logic |
| CON  | Constructs (case, loops, generate, etc.) | Whenever using those constructs |
| DFT  | Design for test, scan-friendliness | When scan/test is in scope |
| LAN  | Language usage (Verilog/VHDL legality, portability) | Always |
| NAM  | Naming conventions | Always |
| PAD  | Pad cells, I/O | Top-level / chip boundary |
| PAR  | Partitioning, hierarchy | Module decomposition |
| SET  | Setup / project structure | Project bootstrap |
| STR  | Structural / style rules (the largest category) | Always |

## Policy documents

The `pol_*.html` files are long reference manuals. Don't read them unless the user asks for that depth or the task touches their topic specifically:

- `pol_stylgd_verilog_eng.html` — Verilog style guide (deep reference)
- `pol_stylgd_vhdl_eng.html` — VHDL style guide (deep reference)
- `pol_ieee_verilog.html` / `pol_ieee_vhdl.html` — IEEE language refs
- `pol_cdc.html` — clock-domain crossing methodology
- `pol_dft.html` — DFT methodology
- `pol_constraints.html` — synthesis constraints
- `pol_power.html` — low-power design
- `pol_rmm.html` — Reuse Methodology Manual conventions
- `pol_dc.html`, `pol_formality.html`, `pol_vcs.html`, `pol_scirocco.html`, `pol_designware.html`, `pol_xilinx.html`, `pol_leda.html`, `pol_verilint.html` — tool-specific guides

## Output conventions

- Default to **Verilog-2001 / SystemVerilog-2012** unless the user specifies otherwise; mirror existing project style if RTL already exists.
- Prefer synchronous reset unless the project uses async (check `RST` rules).
- Always declare a clear sensitivity list (`always_ff @(posedge clk)` / `process(clk)`).
- Name signals per the `NAM` rules (active-low suffix `_n`, clock prefix `clk_`, reset prefix `rst_` or `rstn_`, etc. — confirm in `rule-index.md`).
- Cite the rule ID in a comment **only** when the choice is non-obvious; do not annotate every line.
