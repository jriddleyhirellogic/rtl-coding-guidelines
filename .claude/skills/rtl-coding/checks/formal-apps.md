# Formal App Requirements (`FA_*`)

Targeted formal apps are not lint — you point them at a specific question. But each one imposes
**coding requirements on the RTL** so that the app can be set up cheaply and converge. Those
requirements are what this file captures: write RTL this way and the app runs; write it the other
way and you spend a month on setup.

The Cadence Jasper platform apps referenced below: Superlint, FPV, Sequential Equivalence
Checking (SEC), Design Coverage Verification, Coverage Unreachability, X-Propagation, Control and
Status Register (CSR), Connectivity Verification, Behavioral Property Synthesis, Low-Power
Verification, Security Path Verification (SPV), Clock Domain Crossing, and FSV. Siemens Questa
has broadly equivalent offerings (Questa CDC/RDC, SLEC for equivalence, Questa Formal/Inspect).

---

## Setup and convergence

### `FA_CONSTR` — Design so legal input behaviour is constrainable
**Tools:** all formal apps · **Kind:** app · **Severity:** must
**Overlaps:** none — gap
**Finds:** a block whose legal input space cannot be described without modelling half the chip.
Formal assumes *every* input combination unless constrained; an unconstrainable interface means
every run drowns in illegal-stimulus counterexamples.
**RTL rule:** put a standard, self-describing protocol at block boundaries (a ready/valid
handshake, an AXI/APB subset) rather than an ad-hoc bundle of side-band signals with implicit
timing relationships. If you invent an interface, write its rules down as assertions in the same
file — those assertions become the formal constraints for free.

### `FA_SIZE` — Keep formally-verifiable blocks bounded
**Tools:** all formal apps · **Kind:** app · **Severity:** should
**Overlaps:** `NTL_STR21` (hierarchy depth), `NTL_STR67` (flops per clock domain), `NTL_STR99`
**Finds:** state-space blowup. Wide counters, deep FIFOs and large memories are the usual causes.
**RTL rule:** parameterise depths and widths so they can be shrunk for a formal run
(`FIFO_DEPTH` 4 instead of 512). A block that can only be built at full size cannot be proven.
Keep control logic in a module separate from bulk storage — `NTL_PAR12`/`NTL_PAR13` already push
this way for other reasons.

### `FA_BBOX` — Make black boxes cleanly separable
**Tools:** all formal apps · **Kind:** app · **Severity:** should
**Overlaps:** `NTL_STR22`, `NTL_DFT37`, `NTL_DFT57`
**Finds:** memories, analogue blocks and encrypted IP tangled into control logic so they cannot be
abstracted away.
**RTL rule:** instantiate hard IP behind a thin wrapper with a registered interface, so the formal
run can replace it with a free-input abstraction.

---

## Clock and reset domain crossing

### `FA_CDCSTRUCT` — Use recognisable synchronizer structures
**Tools:** Jasper CDC · Questa CDC · **Kind:** app · **Severity:** must
**Overlaps:** `NTL_CLK05`, `NTL_CLK23`–`NTL_CLK27`, `NTL_STR14`, `NTL_STR15`, `NTL_STR86`,
`NTL_CLK34`, and `pol_cdc.html`
**Finds:** a crossing the tool cannot classify, so it cannot decide whether it is safe. Leda's
`CLK05` requires two flops; a CDC app additionally requires the structure be *recognisable* and
that no combinational logic sit between the flops.
**RTL rule:** put every synchronizer in a dedicated, uniquely-named module (`NTL_STR15`) with no
logic between stages and no fanout from the first stage (`NTL_STR86`). Use the project's standard
`sync_2ff` / `sync_pulse` / `sync_handshake` / `async_fifo` cells rather than hand-rolling. A
hand-rolled crossing is the single most common reason a CDC signoff slips.

### `FA_CDCDATA` — Gray-code or handshake multi-bit crossings
**Tools:** Jasper CDC · Questa CDC · **Kind:** app · **Severity:** must
**Overlaps:** `NTL_CLK24`, `NTL_CLK26`
**Finds:** a multi-bit bus crossed through parallel two-flop synchronizers — each bit resolves
independently, so the destination can observe a value that never existed.
**RTL rule:** never synchronize a multi-bit bus bit-by-bit. Use Gray coding (pointers only, where
exactly one bit changes per increment), or a handshake/MCP structure where data is held stable
while a synchronized control bit signals readiness, or an async FIFO.

### `FA_RDC` — Reset domain crossing
**Tools:** Jasper CDC (covers RDC) · Questa RDC · **Kind:** app · **Severity:** must
**Overlaps:** `NTL_RST24`, `NTL_CLK30` — Leda has the structural check but no methodology
**Finds:** a path from a flop reset by one reset to a flop reset by another (or none). When the
source resets asynchronously and the destination does not, the destination can capture a changing
value and go metastable — the same failure as a CDC, caused by reset rather than clock.
**RTL rule:** keep reset domains aligned with clock domains. Where a crossing is unavoidable,
either synchronize the data, or isolate it during reset, or ensure the destination is held in
reset whenever the source is. Reset removal must be synchronized to the destination clock
(`DO_RSTSYNC`).

### `FA_RSTSEQ` — Make reset assertion/removal analysable
**Tools:** Jasper CDC/RDC · Questa RDC · **Kind:** app · **Severity:** should
**Overlaps:** `NTL_RST06`, `NTL_RST22`, `NTL_PAR18`, `NTL_PAR19`
**Finds:** resets generated deep in the hierarchy, gated locally, or derived from functional
state — none of which the tool can trace to a root.
**RTL rule:** generate all resets in one top-level module (`NTL_RST22`, `NTL_PAR18`), pass them
down as ports, and never gate them locally (`NTL_RST08`).

---

## X-propagation

### `FA_XPROP` — No unexpected X reaches an observable point
**Tools:** Jasper X-Propagation Verification App · Questa Formal · **Kind:** app · **Severity:** must
**Overlaps:** none — gap
**Finds:** sources of X and the conditions that let them propagate. The app analyses the RTL to
ensure no unexpected X values emerge and propagate, creating and executing the checks
automatically. This matters because RTL simulation is *X-optimistic*: a `case` on an X selector
takes the default, an `if` on X takes the else, so simulation reports clean where gates would be
corrupt.
**RTL rule:** reset anything whose X can reach a control path. Do not assign `'x` as a don't-care
in blocks that feed control (`AF_XASSIGN`). Initialise memories, or gate their outputs until first
write. Be especially careful with uninitialised read data driving a state machine.

---

## Equivalence and connectivity

### `FA_SEC` — Keep RTL sequentially comparable across revisions
**Tools:** Jasper Sequential Equivalence Checking (SEC) · Questa SLEC · **Kind:** app · **Severity:** should
**Overlaps:** `pol_formality.html` covers combinational equivalence only
**Finds:** SEC takes two RTL models and proves their sequential behaviour equivalent — the tool of
choice for proving a clock-gating insertion, a pipeline retiming, a bug fix, or an ECO changed
nothing else. It fails to set up when the two models have gratuitously different interfaces.
**RTL rule:** when optimising or restructuring, keep the port list and the cycle-level interface
contract identical, and change one thing at a time. Latency changes are provable but require
mapping; gratuitous port renaming is not.

### `FA_CONN` — Make top-level connectivity declarative
**Tools:** Jasper Connectivity Verification App · **Kind:** app · **Severity:** should
**Overlaps:** `NTL_CON26`, `NTL_CON27`, `NTL_STR05`, `NTL_STR07`
**Finds:** SoC-level connectivity that cannot be checked against a spreadsheet because it is
buried in glue logic.
**RTL rule:** top-level should be structural instantiation and wiring only — no glue logic
(`NTL_STR07`). Keep the same signal name through the hierarchy (`NTL_STR05`) so a connectivity
table can be written and proven.

### `FA_CSR` — Make registers machine-describable
**Tools:** Jasper Control and Status Register App · **Kind:** app · **Severity:** should
**Overlaps:** none — gap
**Finds:** control/status registers hand-coded such that they cannot be checked against an IP-XACT
or RDL description — wrong reset value, wrong access type, missing side effect.
**RTL rule:** generate the register file from the same machine-readable description the software
team uses, rather than hand-coding it. If you must hand-code, keep one register per `always_ff`
block with access behaviour obvious from the code.

---

## Coverage, safety and security

### `FA_UNREACH` — Coverage unreachability
**Tools:** Jasper Coverage Unreachability App · Jasper Design Coverage Verification App
**Kind:** app · **Severity:** should
**Overlaps:** none — gap
**Finds:** coverage holes that are *provably* unreachable, so they can be waived formally rather
than chased by the simulation team. This is often the fastest return on a formal licence: it
converts weeks of coverage-closure argument into a proof.
**RTL rule:** none directly, but note the interaction with `DO_ELEM`: for DO-254 elemental
analysis, formally-proven unreachability is strong evidence for a coverage waiver — and provably
unreachable code is also dead code that must be justified or removed.

### `FA_SAFETY` — Fault propagation / FMEDA
**Tools:** Jasper FSV (functional safety verification) · **Kind:** app · **Severity:** must where a
safety standard applies
**Overlaps:** none — gap
**Finds:** whether an injected fault (a flipped bit) propagates to an observable output and
whether the safety mechanism detects it. Produces the diagnostic coverage numbers an ISO 26262
FMEDA needs, and supports DO-254 safety-specific analysis.
**RTL rule:** keep safety mechanisms (ECC, parity, duplication, CRC) structurally separate from
the logic they protect, so fault injection can target one and observe the other. Do not let
synthesis merge duplicated logic — use the appropriate `dont_touch`/`keep` attributes and check
they survived.

### `FA_SPV` — Security path verification
**Tools:** Jasper Security Path Verification App · **Kind:** app · **Severity:** must where a
security requirement applies
**Overlaps:** none — gap
**Finds:** whether data can flow from a secure source to an insecure destination by *any* path,
including paths through control logic that a designer would not consider a data path.
**RTL rule:** make the isolation point explicit and single — one gating structure per boundary,
placed where it can be named as a proof cut-point. Diffuse isolation scattered across many
conditions is hard to prove and easy to bypass.

### `FA_LPV` — Low-power structure
**Tools:** Jasper Low-Power Verification App · **Kind:** app · **Severity:** should
**Overlaps:** `pol_power.html`, `NTL_CLK07`, `NTL_CLK28`, `NTL_CLK44`, `NTL_CLK45`
**Finds:** missing isolation or retention, corruption on power-down, wrong power-up sequencing —
checked against the UPF/CPF intent.
**RTL rule:** keep power domain boundaries on module boundaries so isolation and level shifters
can be inserted structurally. Never let a domain-crossing signal fan out before isolation.
