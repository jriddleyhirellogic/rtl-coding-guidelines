# Auto-Formal Checks (`AF_*`)

Checks a formal engine derives **automatically from the RTL**, with no testbench, no stimulus and
no hand-written SVA. Two tools dominate:

- **Siemens Questa Inspect** — formerly *Questa AutoCheck*; the rename is recent, and much
  existing material still says AutoCheck. Groups its rules as arithmetic, bus, case,
  combinational, logic, register and FSM.
- **Cadence Jasper Superlint** — combines structural lint (naming, coding style,
  simulation/synthesis mismatch, arithmetic overflow, out-of-bounds index) with auto-formal
  checks (dead code, FSM reachability/deadlock/livelock) generated as IEEE-standard SVA.

The Jasper Superlint flow, as published: *rules selection → compilation / structural checks →
tool setup → auto-formal property generation → auto-formal proof run → results debug.* The
important consequence for RTL authors is the **tool setup** step — an auto-formal run assumes
every input combination is legal unless constrained, so unconstrained inputs produce
counterexamples that are noise. Design so that legal input behaviour is expressible as simple
constraints (see `FA_CONSTR`).

Two properties make this family worth adopting even if you already run Leda:

1. These are **proofs**, not pattern matches. "This state is unreachable" is established over all
   inputs and all time, not guessed from topology.
2. A failing check comes with a **counterexample waveform** — a concrete trace to the bug.

---

## FSM checks

### `AF_FSMDEAD` — FSM deadlock
**Tools:** Questa Inspect (FSM rules: deadlock) · Jasper Superlint (auto-formal deadlock)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** none — gap in `NTL_*`
**Finds:** a state, or set of states, the FSM can enter and provably never leave. The published
Intel/Jasper experience report describes exactly this: a pipeline hang that only occurred when a
pointer exceeded 5 on the precise clock where a transfer was reinitiated — a corner case that
escaped the pre-silicon test environment and was caught by the auto-generated deadlock check.
**RTL rule:** every state must have a reachable path back to idle/reset. Give every FSM a
`default:` that returns to a safe state, and make sure any handshake wait state has a timeout or
an abort input. Never rely on "the other side will always respond".

```systemverilog
// BAD — WAIT is a deadlock if ack never arrives
WAIT: if (ack) next = DONE;          // no else, no escape

// GOOD — bounded wait with an escape
WAIT: if (ack)            next = DONE;
      else if (timeout_q) next = ERR;
      else                next = WAIT;
```

### `AF_FSMLIVE` — FSM livelock
**Tools:** Questa Inspect (FSM rules: livelock) · Jasper Superlint
**Kind:** auto-formal · **Severity:** must
**Overlaps:** none — gap
**Finds:** the FSM cycles forever among a subset of states without making progress. Distinct from
deadlock: it keeps moving, it just never finishes. Typical of two interacting FSMs each backing
off for the other.
**RTL rule:** any retry or arbitration loop needs a bounded retry counter or a priority that
breaks ties asymmetrically.

### `AF_FSMREACH` — Unreachable FSM state
**Tools:** Questa Inspect (FSM rules: reachability) · Jasper Superlint (FSM reachability)
**Kind:** auto-formal · **Severity:** should
**Overlaps:** none — gap
**Finds:** an encoded state that no input sequence can ever reach.
**RTL rule:** an unreachable state is either dead code to delete, or a symptom that the transition
logic is wrong and a state you *intended* to reach is gated off. Investigate before deleting.
Note the tension with `DO_SAFEFSM`: for safety-critical work, unreachable *illegal* encodings must
still be handled defensively, and the tool flagging them as unreachable is the expected result,
not a finding to act on.

---

## Arithmetic checks

### `AF_OVFL` — Arithmetic overflow / value overflow
**Tools:** Questa Inspect (arithmetic rules: value overflow) · Jasper Superlint (structural
arithmetic overflow)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** none — gap
**Finds:** an expression whose result provably exceeds the width of its target, silently
truncating. The classic is accumulating into a register the same width as its addends.
**RTL rule:** size accumulators to `$clog2(max_terms) + operand_width`, or saturate explicitly.
Never rely on implicit truncation for correctness; if wrapping *is* intended, say so in a comment
so the check can be waived with a rationale.

```systemverilog
// BAD — sum wraps silently at 8 bits
logic [7:0] sum;
always_ff @(posedge clk) sum <= sum + delta;

// GOOD — explicit width, explicit saturation
logic [8:0] sum_ext;
assign sum_ext = {1'b0, sum} + {1'b0, delta};
always_ff @(posedge clk) sum <= sum_ext[8] ? 8'hFF : sum_ext[7:0];
```

### `AF_DIV0` — Divide by zero
**Tools:** Questa Inspect (arithmetic rules: divide-by-zero)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** none — gap
**Finds:** a divide or modulo whose divisor can provably be zero.
**RTL rule:** guard every divisor, or constrain it structurally so zero is unrepresentable. Do not
assume software will never program a zero divisor.

### `AF_RANGE` — Array / memory index out of bounds
**Tools:** Questa Inspect (out-of-range memory indexing) · Jasper Superlint (out-of-bounds index)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** none — gap
**Finds:** an index expression that can exceed the declared bounds of an array or memory. In
simulation this returns X; in synthesis the behaviour is whatever the decode happens to do.
**RTL rule:** make the index width exactly `$clog2(DEPTH)` and make `DEPTH` a power of two, or
range-check the index and force a safe value. Beware the non-power-of-two case — a 5-bit index
into a 24-entry array has 8 illegal values.

---

## Bus and driver checks

### `AF_MULTIDRV` — Multiply-driven bus or register
**Tools:** Questa Inspect (bus rules: multiply-driven; register rules: multiply-driven)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** `NTL_STR19`, `NTL_STR62`, `NTL_STR72`, `NTL_STR76`, `NTL_STR89`, `NTL_STR110`
**Finds:** two drivers provably active at once. Leda finds the *structure*; the formal check
proves whether the enables can actually overlap, which kills the false positives Leda reports on
mutually exclusive enables.
**RTL rule:** one driver per net inside a module. Where a shared bus is unavoidable, prove enable
exclusivity with an assertion rather than by inspection.

### `AF_UNDRIVEN` — Undriven / floating bus
**Tools:** Questa Inspect (bus rules: undriven buses; logic rules: undriven logic)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** `NTL_CON12`, `NTL_CON12A`, `NTL_CON12B`, `NTL_CON12C`, `NTL_CON08`
**Finds:** a net with no active driver in some reachable state — a floating bus that will read X.
**RTL rule:** every tri-state bus needs a default/park driver or a bus keeper (`NTL_STR73`).
Better: do not use internal tri-states at all (`NTL_STR34`, `DO_NOTRI`).

### `AF_ONEHOT` — One-hot / one-cold conformance
**Tools:** Questa Inspect (bus rules: one-hot/one-cold conformance)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** none — gap
**Finds:** a vector documented or decoded as one-hot that can provably take a non-one-hot value.
This is a frequent source of silent mux corruption, because one-hot muxes built from AND-OR trees
produce garbage rather than X when two bits are set.
**RTL rule:** state one-hot intent as an assertion next to the declaration. If the source is
software-writable, decode defensively rather than assuming.

### `AF_STUCK` — Stuck-at register
**Tools:** Questa Inspect (register rules: stuck-at registers)
**Kind:** auto-formal · **Severity:** should
**Overlaps:** partially `NTL_CON24`, `NTL_STR79`
**Finds:** a register that provably never changes from its reset value — usually an enable that is
never asserted, or a feature left half-wired.
**RTL rule:** either remove it or fix the enable. A stuck register that survives to silicon is
area and leakage for nothing, and under DO-254 it is unintended function (`DO_NODEAD`).

### `AF_NORESET` — Un-resettable register
**Tools:** Questa Inspect (register rules: un-resetable registers)
**Kind:** auto-formal · **Severity:** should (must for DAL A/B — see `DO_RSTALL`)
**Overlaps:** `NTL_RST03`, `NTL_DFT38`, `NTL_STR82`
**Finds:** a register with no reset whose value can be observed before it is first written — so
the design's behaviour depends on power-up state.
**RTL rule:** reset all control state. Datapath registers may skip reset for area if, and only if,
you can show the data is always written before it is read.

---

## Case statement checks

### `AF_CASEFULL` — `case` not full
**Tools:** Questa Inspect (case rules: full case conformance)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** none — gap
**Finds:** a `case` with reachable uncovered selector values. Where the statement is marked
`full_case` or `unique`, this is worse than a latch: synthesis is entitled to treat the uncovered
values as don't-cares, so RTL simulation and gates diverge.
**RTL rule:** always write a `default:`. Never use the `full_case` pragma. Prefer `unique case`
only where you have also proven the selector cannot take other values.

### `AF_CASEPAR` — `case` not parallel
**Tools:** Questa Inspect (case rules: parallel case conformance)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** none — gap
**Finds:** overlapping case items where the design was marked `parallel_case`/`unique`. Simulation
takes the first match; synthesis builds a parallel mux and may take another.
**RTL rule:** if items genuinely overlap and order matters, write `priority case` or an
`if/else if` chain and let it synthesise as a priority encoder. Never assert parallelism you have
not proven.

### `AF_CASEDEF` — Unreachable `default` branch
**Tools:** Questa Inspect (case rules: default case branching)
**Kind:** auto-formal · **Severity:** consider
**Overlaps:** none — gap
**Finds:** a `default:` that can never execute. Usually benign and intentional — defensive coding
that the tool has proven redundant.
**RTL rule:** keep the default anyway. Waive this check rather than deleting defensive code; under
DO-254 the defensive branch is required (`DO_SAFEFSM`) even when provably unreachable.

---

## Combinational and logic checks

### `AF_COMBLOOP` — Combinational feedback loop
**Tools:** Questa Inspect (combinational logic rules: combinational feedback loop)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** `NTL_STR33`, `NTL_STR71`, `NTL_STR78`
**Finds:** a zero-delay logic loop. Non-deterministic in simulation, unroutable timing in
synthesis, and unanalysable by STA.
**RTL rule:** break every loop with a register. The only acceptable exceptions are explicitly
instantiated library cells (ring oscillators, bus keepers), never inferred logic.

### `AF_DEADCODE` — Dead / unreachable code
**Tools:** Questa Inspect (dead code analysis) · Jasper Superlint (auto-formal dead-code)
**Kind:** auto-formal · **Severity:** must
**Overlaps:** `NTL_CON32`, `NTL_CON33`, `NTL_LAN15` — but only weakly; Leda reasons about
netlist connectivity, not reachability over time
**Finds:** RTL that no input sequence can ever execute. Distinct from "unused signal": the code is
connected and looks live, but the enabling condition is unsatisfiable.
**RTL rule:** delete it, or fix the condition that was supposed to enable it. For DO-254 this is
not optional — see `DO_NODEAD`.

### `AF_UNUSED` — Unused logic
**Tools:** Questa Inspect (logic rules: unused logic) · Jasper Superlint (structural)
**Kind:** structural · **Severity:** should
**Overlaps:** `NTL_LAN15`, `NTL_CON09`, `NTL_CON13`
**Finds:** logic whose output reaches no observable point.
**RTL rule:** delete, or connect it. Check for a typo'd signal name first — unused logic very
often means a similarly-named signal got connected instead.

### `AF_XASSIGN` — Explicit X assignment
**Tools:** Questa Inspect · Jasper Superlint · see also `FA_XPROP`
**Kind:** auto-formal · **Severity:** must (for DO-254, `DO_NOX`)
**Overlaps:** none — gap
**Finds:** RTL that assigns `'x` as a synthesis don't-care, where the X can reach an observable
output. Simulation X-optimism can hide this entirely: `if (x_val)` takes the false branch in
simulation but the gates take whatever the real value is.
**RTL rule:** for safety-critical or X-sensitive designs, assign a defined constant rather than
`'x`. Where `'x` is deliberately used for synthesis freedom, confirm it is blocked by a downstream
enable and record that reasoning.

### `AF_SIMSYN` — Simulation / synthesis mismatch
**Tools:** Jasper Superlint (structural) · Questa Inspect
**Kind:** structural · **Severity:** must
**Overlaps:** partially `NTL_STR01`, `NTL_STR02`
**Finds:** constructs that mean different things to the simulator and the synthesiser: incomplete
sensitivity lists, blocking assignments in sequential blocks, `full_case`/`parallel_case` pragmas,
functions with side effects, delays in RTL.
**RTL rule:** `always_ff` with non-blocking only; `always_comb` with blocking only; never mix.
No pragmas that promise what you have not proven. No `#` delays in synthesisable code.

### `AF_NAMING` — Naming and coding style
**Tools:** Jasper Superlint (structural: naming, coding style)
**Kind:** structural · **Severity:** consider
**Overlaps:** the whole `NTL_NAM*` category, plus `NTL_LAN21`, `NTL_LAN22`, `NTL_LAN24`
**Finds:** naming convention violations.
**RTL rule:** Leda's `NAM` rules already cover this and are more specific. Configure the formal
tool's naming rules to match `NTL_NAM01`–`NTL_NAM18` rather than running two conflicting
conventions.
