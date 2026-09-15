---
name: rtl-coding
description: Generate, review, or refactor RTL code (Verilog, SystemVerilog, VHDL) following the Synopsys Leda / RMM coding guidelines bundled with this skill, plus supplementary auto-formal, formal-app, DO-254 and modern-lint check families. Use when the user asks to write, modify, or review RTL — module/entity definitions, FSMs, clock/reset logic, FIFOs, synchronizers, pads, parameterized blocks, testbenches that interact with DUT RTL — or when reviewing RTL for lint/CDC/DFT issues. Also use when the user asks about a specific rule ID like `NTL_CLK05`, `AF_FSMDEAD` or `DO_NOLATCH`; about clock-domain-crossing, reset, naming, partitioning, structure, or DFT conventions; about safety-critical or certifiable RTL (DO-254, DAL A/B, airborne hardware); or about checks from formal and lint tools such as Jasper/JasperGold Superlint, Questa AutoCheck/Inspect, VC SpyGlass, Verilator or Verible.
---

# RTL Coding Guidelines Skill

This skill applies a curated set of RTL coding rules when generating or reviewing Verilog,
SystemVerilog, and VHDL. Two corpora:

- **`NTL_*`** — the Synopsys Leda rules, plus `pol_*.html` policy documents. Structural and
  netlist lint: connectivity, gate topology, clock/reset tree shape, scan structure.
- **`AF_*` / `FA_*` / `DO_*` / `ML_*`** — supplementary check families covering what Leda does
  not: behavioural properties provable by formal tools, the RTL requirements formal apps impose,
  DO-254 design assurance, and modern SystemVerilog lint.

## Rule corpus location

```
<RULES_ROOT>/
  NTL_<CAT><NN>.html                     # individual Leda rules
  pol_*.html                             # large policy documents
  .claude/skills/rtl-coding/
    rule-index.md                        # ONE-LINE SUMMARY OF EVERY RULE AND CHECK — start here
    checks/README.md                     # what the supplementary families are, and the ID scheme
    checks/auto-formal.md                # AF_* — Questa Inspect / Jasper Superlint auto-formal
    checks/formal-apps.md                # FA_* — CDC/RDC, X-prop, SEC, connectivity, safety, ...
    checks/do254.md                      # DO_* — DO-254 airborne design assurance
    checks/modern-lint.md                # ML_* — VC SpyGlass, Verilator, Verible, svlint
```

`<RULES_ROOT>` is the directory three levels above this `SKILL.md` (i.e. the repo root). The skill
is designed to be installed as a symlink from `~/.claude/skills/rtl-coding` →
`<repo>/.claude/skills/rtl-coding`, so relative paths from this file resolve correctly.

If invoked from outside the repo, ask the user for the path to the rule corpus before proceeding.

**Do not load the whole corpus.** There are 264 `NTL_*` files plus 18 long policy documents.
`rule-index.md` exists so you can find the handful that matter and read only those.

---

## Step 0 — establish the project profile

Before generating or reviewing, determine three things. Ask if the answer is not evident from the
existing code or the user's request, because they change which checks apply:

1. **Language and vintage** — VHDL, Verilog-2001, or SystemVerilog? The `ML_*` family applies only
   to SystemVerilog; much of it is meaningless for VHDL.
2. **Target** — ASIC or FPGA? `PAD`, `DFT` and much of `STR` are ASIC-oriented.
3. **Assurance level** — is this safety-critical (DO-254, ISO 26262) or commercial? This is the
   big one. The `DO_*` family is *stricter* than commercial practice and in three places actively
   contradicts it (see **Conflicts** below). Do not apply `DO_*` to commercial RTL unasked, and do
   not skip it on certifiable RTL.

Default when unstated: SystemVerilog, ASIC, commercial. Say which profile you assumed.

---

## Workflow

### Generating RTL

1. **Identify scope.** What block? (FSM, FIFO, synchronizer, arbiter, pad, top-level glue, …)
2. **Pick relevant categories** — do not load every rule:
   - Always: `NAM`, `STR`, `LAN`, plus `ML_*` for SystemVerilog.
   - Anything sequential: `CLK`, `RST`.
   - Any FSM: `AF_FSMDEAD`, `AF_FSMLIVE`, `AF_FSMREACH`, and `DO_SAFEFSM` if certifiable.
   - Any arithmetic: `AF_OVFL`, `AF_DIV0`, `AF_RANGE`, `ML_WIDTH`, `ML_SIGN`.
   - Any memory or array indexing: `AF_RANGE`.
   - Multi-clock or async inputs: `CLK05`, `CLK04`, `FA_CDCSTRUCT`, `FA_CDCDATA`, `FA_RDC`,
     plus `pol_cdc.html`.
   - Test/scan: `DFT`. I/O cells: `PAD`. Hierarchy: `PAR`, `FA_SIZE`.
   - Certifiable work: the whole `DO_*` family.
3. **Read `rule-index.md`** to find the specific IDs. Read individual `NTL_<ID>.html` or the
   relevant `checks/*.md` section only where the one-line summary is not enough.
4. **Write the RTL.** Conform to every rule in the categories you selected.
5. **Self-check** against those categories before returning, and fix what you find.

### Reviewing RTL

1. Read the file(s).
2. Walk the applicable categories in `rule-index.md` — typically `NAM`, `STR`, `LAN`, `CLK`,
   `RST`, `ML_*`, plus `DFT`/`PAD` and `DO_*` per the profile.
3. For each likely violation, read the matching `NTL_<ID>.html` or `checks/*.md` entry to confirm,
   and quote the rule.
4. Report as: `RULE_ID — file:line — what's wrong — suggested fix`.
5. Order findings by severity, and say explicitly which checks you could **not** evaluate by
   reading — `AF_*` and `FA_*` mostly require running the tool. Flag those as "candidate, needs
   formal run" rather than asserting a violation you cannot prove by inspection.

### Explaining a rule

Read `NTL_<ID>.html` (Leda) or the entry in the relevant `checks/*.md` (supplementary), then
summarize: message, severity, language scope, why it matters, and a good/bad example.

---

## Conflicts between families

These are real and must be handled deliberately rather than silently picking one side:

| Conflict | Resolution |
|----------|------------|
| `AF_FSMREACH` / `AF_CASEDEF` report defensive `default:` branches as unreachable, but `DO_SAFEFSM` **requires** them | On certifiable RTL, keep the defensive code and waive the formal finding with a rationale. The tool is right and the code is also right. |
| `AF_NORESET` tolerates unreset datapath registers; `DO_RSTALL` does not | Commercial: reset control state, datapath optional. Certifiable: reset everything. |
| `NTL_RST03` mandates async set/reset on all registers; modern FPGA practice prefers synchronous reset | Follow the existing project's convention. If starting fresh, ask. |
| Leda's `NAM` rules and a formal tool's naming rules (`AF_NAMING`) may disagree | `NTL_NAM*` wins — it is more specific. Configure the other tool to match rather than running two conventions. |

When a rule set genuinely conflicts with what the user asked for, say so in a sentence and
proceed with their request — do not silently rewrite their intent to satisfy a lint rule.

---

## Categories at a glance

### Leda (`NTL_*`) — structural

| Code | Topic | When to consult |
|------|-------|-----------------|
| CLK  | Clocks, gating, edges, domains | Any sequential logic |
| RST  | Reset style, sync vs async, polarity | Any sequential logic |
| CON  | Connectivity (ports, nets, tie-offs) | Netlist / integration work |
| DFT  | Design for test, scan-friendliness | When scan/test is in scope |
| LAN  | Language usage (legality, portability) | Always |
| NAM  | Naming conventions | Always |
| PAD  | Pad cells, I/O | Top-level / chip boundary |
| PAR  | Partitioning, hierarchy | Module decomposition |
| SET  | Set-domain rules | Designs using async set |
| STR  | Structural / style (largest category) | Always |

### Supplementary — behavioural and process

| Prefix | Topic | When to consult |
|--------|-------|-----------------|
| `AF_` | Auto-formal: FSM deadlock, overflow, out-of-bounds, dead code, X, case conformance | Any FSM, arithmetic, or array indexing |
| `FA_` | Formal-app requirements: CDC/RDC, X-prop, SEC, connectivity, CSR, safety, security | Multi-clock, safety, security, or when a formal flow is in use |
| `DO_` | DO-254 design assurance, DAL-driven | Airborne / safety-critical work only |
| `ML_` | Modern SystemVerilog lint: width, sensitivity, typing, hygiene | Any SystemVerilog |

---

## Policy documents

Long reference manuals in the repo root. Don't read them unless the task needs that depth:

- `pol_stylgd_verilog_eng.html` / `pol_stylgd_vhdl_eng.html` — style guides (deep reference)
- `pol_ieee_verilog.html` / `pol_ieee_vhdl.html` — IEEE language refs
- `pol_cdc.html` — clock-domain crossing methodology (pairs with `FA_CDC*`)
- `pol_dft.html` — DFT methodology
- `pol_constraints.html` — synthesis constraints
- `pol_power.html` — low-power design (pairs with `FA_LPV`)
- `pol_rmm.html` — Reuse Methodology Manual conventions
- `pol_formality.html` — equivalence checking (pairs with `FA_SEC`)
- `pol_dc.html`, `pol_vcs.html`, `pol_scirocco.html`, `pol_designware.html`, `pol_xilinx.html`,
  `pol_leda.html`, `pol_verilint.html` — tool-specific guides

---

## Output conventions

- Default to **Verilog-2001 / SystemVerilog-2012** unless told otherwise; mirror existing project
  style if RTL already exists.
- Start every SystemVerilog file with `` `default_nettype none `` (`ML_IMPLICIT`) — highest-value
  single line in the corpus.
- `always_ff` with non-blocking only; `always_comb` with blocking only; never mixed (`ML_ALWAYS`,
  `ML_BLOCKING`).
- Every `case` gets a `default:` (`AF_CASEFULL`). No `casex` (`ML_CASEX`). No `full_case` /
  `parallel_case` pragmas (`AF_CASEPAR`).
- Explicit widths everywhere; size every constant (`ML_WIDTH`).
- Prefer synchronous reset unless the project uses async — check the `RST` rules and the existing
  code.
- Name signals per the `NAM` rules (active-low suffix `_n`/`_N`, clock prefix `clk`, reset prefix
  `rst`, registered output suffix `_r` — confirm in `rule-index.md`).
- Cite a rule ID in a comment **only** where the choice is non-obvious (e.g.
  `// NTL_CLK05: double-flop synchronizer`, `// DO_SAFEFSM: SEU recovery, do not delete`). Do not
  annotate every line.

---

## Regenerating the index

After adding or editing any `NTL_*.html` or `checks/*.md`:

```bash
./.claude/skills/rtl-coding/build-index.sh
```

It scrapes rule messages from the HTML and `### \`ID\` — title` headings from `checks/*.md`, so
new checks must follow that heading format to be indexed.
