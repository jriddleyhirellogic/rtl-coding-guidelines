# Modern Lint Checks (`ML_*`)

The `NTL_*` corpus predates SystemVerilog-2012 as everyday RTL. It reasons in terms of Verilog-95
/ VHDL-93 and gate-level netlists, so it has nothing to say about `always_comb`, `logic`,
interfaces, packages, or the classes of mistake those constructs introduce and prevent.

This file covers what a current lint flow adds. Tools referenced:

- **Synopsys VC SpyGlass** — the current Synopsys lint/CDC/RDC platform, and the effective
  successor to the Leda flow these `NTL_*` rules came from. If you are modernising, this is the
  migration target.
- **Verilator** (`--lint-only -Wall`) — free, fast, and unusually good at width and
  sensitivity bugs. Worth wiring into CI even on a fully commercial flow.
- **Verible** (`verible-verilog-lint`) — Google's SystemVerilog style linter and formatter.
- **svlint** — open-source, rule-configurable SystemVerilog linter.

A practical note: Verilator and Verible cost nothing and run in seconds. Putting them in CI
catches a large fraction of the findings below before anyone spends a commercial licence-hour.

---

## Width and type

### `ML_WIDTH` — Implicit width mismatch
**Tools:** Verilator (`WIDTH`, `WIDTHEXPAND`, `WIDTHTRUNC`) · VC SpyGlass · svlint
**Kind:** structural · **Severity:** must
**Overlaps:** none — gap
**Finds:** an assignment or comparison where operand widths differ and the language silently
zero-extends or truncates. The single most common real bug lint catches, and invisible in review.
**RTL rule:** make every width explicit. Size constants (`8'd0`, not `0`). Use `$clog2` for index
widths. Where truncation is intended, write the part-select so the intent is on the page.

```systemverilog
// BAD — silently truncates; nobody notices
logic [7:0]  small;
logic [15:0] big;
assign small = big;

// GOOD — intent is explicit and reviewable
assign small = big[7:0];
```

### `ML_SIGN` — Signed/unsigned mixing
**Tools:** Verilator (`WIDTH`) · VC SpyGlass · **Kind:** structural · **Severity:** must
**Overlaps:** none — gap
**Finds:** an expression mixing signed and unsigned operands, where the whole expression becomes
unsigned and a negative value becomes a large positive one. Comparisons are the usual casualty.
**RTL rule:** keep signed arithmetic in explicitly `signed` variables end to end, and use
`$signed()`/`$unsigned()` at the exact point of conversion. Never let a `-1` meet a `logic [7:0]`
unannounced.

### `ML_ENUM` — Weak enum typing
**Tools:** Verible · svlint · VC SpyGlass · **Kind:** structural · **Severity:** should
**Overlaps:** none — gap
**Finds:** FSM states and mode encodings as bare `parameter`/`localparam` bit patterns rather than
an `enum`, losing the compiler's type checking and the waveform viewer's state names.
**RTL rule:** declare state types as `typedef enum logic [N-1:0] {...}`. Debug gets readable state
names and the compiler catches cross-assignment between unrelated enums.

---

## Process blocks

### `ML_ALWAYS` — Use the SystemVerilog always variants
**Tools:** Verible · svlint · VC SpyGlass · Verilator (`ALWCOMBORDER`, `COMBDLY`)
**Kind:** structural · **Severity:** must
**Overlaps:** partially `NTL_STR01`, `NTL_STR47`; see `AF_SIMSYN`
**Finds:** plain `always @(...)` where `always_ff`, `always_comb` or `always_latch` should be used.
The generic form lets the tool infer whatever the sensitivity list implies, including an
unintended latch; the specific forms make the compiler check your intent.
**RTL rule:** `always_ff` for sequential (non-blocking only), `always_comb` for combinational
(blocking only), `always_latch` only where a latch is genuinely wanted — which, per `DO_NOLATCH`,
is nowhere in certifiable RTL.

### `ML_SENS` — Incomplete sensitivity list
**Tools:** Verilator (`ALWCOMBORDER`) · all linters · **Kind:** structural · **Severity:** must
**Overlaps:** none — gap; see `AF_SIMSYN`
**Finds:** a signal read in a combinational block but missing from its sensitivity list — the
canonical simulation/synthesis mismatch.
**RTL rule:** use `always_comb`, which derives the list. Never hand-write `always @(a or b)`.

### `ML_BLOCKING` — Blocking/non-blocking misuse
**Tools:** Verilator (`COMBDLY`, `BLKSEQ`) · VC SpyGlass · **Kind:** structural · **Severity:** must
**Overlaps:** none — gap; see `AF_SIMSYN`
**Finds:** blocking assignment in a sequential block or non-blocking in a combinational one.
Produces race conditions whose symptoms depend on the simulator's scheduling.
**RTL rule:** `<=` in `always_ff`, `=` in `always_comb`, never mixed within a block, and never the
same variable assigned from two blocks.

---

## Structure and reuse

### `ML_PKG` — Share types through packages
**Tools:** Verible · VC SpyGlass · **Kind:** structural · **Severity:** should
**Overlaps:** partially `NTL_STR05`
**Finds:** the same width, opcode or state encoding redefined in several files — which eventually
diverge.
**RTL rule:** put shared parameters, enums and structs in a package and import it. One definition,
one place to change.

### `ML_PORTNAME` — Named port connections only
**Tools:** Verible · svlint · VC SpyGlass · **Kind:** structural · **Severity:** must
**Overlaps:** partially `NTL_CON22`, `NTL_CON23`
**Finds:** positional port connection in instantiation. A port inserted in the middle of a list
silently rewires everything after it, and nothing in the diff looks wrong.
**RTL rule:** always `.name(signal)`. Treat `.*` with care — convenient, but it hides connections
from review and from `FA_CONN` connectivity checking.

### `ML_GENLABEL` — Label generate blocks
**Tools:** Verible · svlint · **Kind:** structural · **Severity:** should
**Overlaps:** none — gap
**Finds:** unlabelled `generate` blocks, which get tool-assigned names. Those names appear in
hierarchical paths used by constraints, assertions and DFT scripts — and they change when the code
changes.
**RTL rule:** label every generate block and every `for` inside one. Constraint files depend on
hierarchy names being stable.

### `ML_MAGIC` — Magic numbers
**Tools:** Verible · svlint · **Kind:** structural · **Severity:** should
**Overlaps:** none — gap; see `DO_DERIVED`
**Finds:** literal constants in logic rather than named parameters.
**RTL rule:** name every constant that means something. Under DO-254 this is stronger than style —
an unnamed constant is an undocumented derived requirement.

---

## Simulation hygiene

### `ML_UNDRIVEN` — Undriven or unused signal
**Tools:** Verilator (`UNDRIVEN`, `UNUSED`) · all linters · **Kind:** structural · **Severity:** should
**Overlaps:** `NTL_LAN15`, `NTL_CON12*`, `NTL_CON13*`; see `AF_UNUSED`
**Finds:** declared-but-never-driven and driven-but-never-read signals. Usually a typo in a signal
name, so check for a near-identical name before deleting.
**RTL rule:** clean these to zero. A noisy baseline hides the one that matters.

### `ML_IMPLICIT` — Implicit net declaration
**Tools:** Verilator (`IMPLICIT`) · all linters · **Kind:** structural · **Severity:** must
**Overlaps:** partially `NTL_LAN22`
**Finds:** a misspelled signal name silently becoming a new 1-bit wire. A whole bus reduced to one
bit, with no error anywhere.
**RTL rule:** put `` `default_nettype none `` at the top of every file and
`` `default_nettype wire `` at the end. This turns the entire class of typo bug into a
compile error. It is the single highest-value line in this file.

### `ML_CASEX` — No `casex` / `casez`
**Tools:** Verible · svlint · VC SpyGlass · **Kind:** structural · **Severity:** must
**Overlaps:** none — gap; see `AF_CASEPAR`, `DO_NOX`
**Finds:** `casex`/`casez`, where X or Z in the *selector* matches any branch — so a corrupted
selector silently takes a valid-looking path, and simulation and synthesis can disagree about
which.
**RTL rule:** use `case` with explicit masks, or `case inside` with wildcards in SystemVerilog.
`casex` is prohibited outright in safety-critical work.

### `ML_FUNCAUTO` — Non-automatic functions and tasks
**Tools:** Verilator · Verible · **Kind:** structural · **Severity:** should
**Overlaps:** none — gap
**Finds:** static functions/tasks, where concurrent calls share storage and corrupt each other.
**RTL rule:** declare functions and tasks `automatic`. Static lifetime is almost never what you
want, and the failure is intermittent and painful to debug.
