# RTL Coding Guidelines

This repo is a reference corpus of RTL (Verilog / SystemVerilog / VHDL) coding rules — the Synopsys Leda `NTL_*` rules plus several long policy/style documents (`pol_*.html`).

## Don't read every file

There are ~250 rule files. Do **not** load them all into context. Use the skill below — it knows how to look up only what's relevant to the current task.

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

`rule-index.md` is generated from the `NTL_*.html` files. Regenerate it after adding or editing rules:

```bash
./.claude/skills/rtl-coding/build-index.sh
```

## Rule categories

| Code | Topic |
|------|-------|
| CLK  | Clocks, gating, edges, domains |
| RST  | Reset style, sync vs async, polarity |
| CON  | Coding constructs (case, generate, loops, …) |
| DFT  | Design for test |
| LAN  | Language legality / portability |
| NAM  | Naming conventions |
| PAD  | Pad cells / chip I/O |
| PAR  | Hierarchy / partitioning |
| SET  | Project setup |
| STR  | Structural / style rules |

Long-form policy documents are the `pol_*.html` files; consult them only when a task requires that depth.
