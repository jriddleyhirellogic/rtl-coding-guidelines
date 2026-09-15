# Supplementary Check Families

The `NTL_*` corpus in the repo root is Synopsys Leda: **structural and netlist lint**. It is
excellent at what it does and largely blind to everything else. These files add four check
families that Leda does not cover, written as markdown so they are easy to diff and extend.

## Why these exist — the gap in `NTL_*`

Reading the full `rule-index.md`, the Leda corpus is overwhelmingly *structural*: connectivity
(`CON`), gate/cell topology (`STR`), clock and reset tree shape (`CLK`/`RST`), scan structure
(`DFT`). That means it has **no coverage at all** of:

| Gap | Nearest `NTL_*` | Covered here by |
|-----|-----------------|-----------------|
| FSM deadlock / livelock / unreachable state | *(none)* | `AF_FSM*` |
| Arithmetic overflow, divide-by-zero | *(none)* | `AF_OVFL`, `AF_DIV0` |
| Array / memory index out of bounds | *(none)* | `AF_RANGE` |
| X-optimism and X-propagation | *(none)* | `AF_XASSIGN`, `FA_XPROP` |
| `case` fullness / parallelism as a *provable* property | *(none)* | `AF_CASEFULL`, `AF_CASEPAR` |
| Requirements traceability, design assurance process | *(none)* | `DO_*` |
| Formal-tool setup requirements imposed on RTL | *(none)* | `FA_*` |

Leda checks the *shape* of the netlist. These families check the *behaviour* of the RTL, plus
the process obligations that safety-critical programmes put on it.

## Files

| File | Prefix | Covers |
|------|--------|--------|
| `auto-formal.md` | `AF_` | Automatic formal checks needing no testbench — Siemens **Questa Inspect** (formerly Questa AutoCheck) and Cadence **Jasper Superlint** auto-formal |
| `formal-apps.md` | `FA_` | RTL requirements imposed by targeted formal apps — CDC/RDC, X-prop, SEC, connectivity, CSR, safety/FMEDA, coverage unreachability |
| `do254.md` | `DO_` | RTCA/DO-254 airborne electronic hardware design assurance, DAL-driven |
| `modern-lint.md` | `ML_` | Synopsys VC SpyGlass, Verilator, Verible, svlint — checks a 2020s flow adds over Leda |

## ID scheme

IDs here are **ours**, not the vendors'. They are stable handles so the skill, review output, and
waiver files can cite a check the same way they cite `NTL_CLK05`.

> **Tool check names and switches vary by vendor and by release.** Each entry names the tool
> check *conceptually* under **Tools:**, which is enough to find it in that tool's rule browser.
> Do not paste these as literal command-line rule names without confirming against the
> documentation of the version you have installed.

## Entry format

```
### `AF_XXXX` — short title
**Tools:** which tools implement this
**Kind:** structural | auto-formal | app | process
**Overlaps:** existing NTL_* rules that partially cover it (or "none — gap")
**Finds:** what a violation actually is
**RTL rule:** what to do when writing code
```

## Severity convention

- **must** — a real bug or a certification blocker. Fix it.
- **should** — fix unless there is a written, reviewed justification.
- **consider** — style or robustness; project decides.

DO-254 entries additionally carry a **DAL:** line giving the assurance levels at which the rule
is normally mandatory.
