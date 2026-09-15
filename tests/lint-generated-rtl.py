"""Lint the RTL a behavioral eval run generated, with Verilator.

Why this exists: `no-inferred-latch` on the generate cases is a compiler
question, and handing it to a judge model made it non-deterministic - the same
RTL passed 1/3 under haiku and 3/3 under sonnet. Verilator answers it exactly,
for free, every time.

Why it is a post-processing pass and not a grader: `claude plugin eval` grader
types are fixed (regex, tool_used, tool_order, file_exists, llm, baseline) and
none of them runs a command. So the flow is two-phase - run the eval, then lint
what it produced:

    claude plugin eval .claude/skills/rtl-coding --json results.json
    python3 tests/lint-generated-rtl.py results.json

It recovers the model's final message from `llm` grader evidence, because the
run's trace.jsonl is deleted unless the eval ran with --keep-temp. That means a
case with no `llm` grader focused on last_message yields nothing to lint, and
this script says so rather than reporting a silent pass.

Verilator's reach is narrow: no CDC analysis, no clock-tree checks, no naming
conventions. A clean report here is not a clean review - it means the RTL holds
up structurally, which is one question among several.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

# Defects that make generated RTL wrong, not merely untidy.
BLOCKING = {
    "LATCH", "CASEINCOMPLETE", "BLKSEQ", "IMPLICIT",
    "MULTIDRIVEN", "COMBDLY", "ALWCOMBORDER",
}
# Worth seeing, not worth failing a run over.
ADVISORY = {
    "WIDTHTRUNC", "WIDTHEXPAND", "UNUSEDSIGNAL", "UNDRIVEN",
    "UNUSEDPARAM", "VARHIDDEN", "SYNCASYNCNET", "CASEX",
}

FENCE = re.compile(r"```(systemverilog|verilog|sv)\n(.*?)```", re.S)
MODULE = re.compile(r"^\s*(module|package|interface)\b", re.M)
CODE = re.compile(r"%(?:Warning-([A-Z0-9]+)|Error(?:-([A-Z0-9]+))?)")


def complete_modules(text):
    """Fenced blocks that define a whole module.

    A review answers in fragments - the offending case statement, the corrected
    always block - and those are not compilable on their own. Linting them
    reports errors about the extraction, not about the RTL, so only blocks that
    open a module and close it are candidates.
    """
    out = []
    for m in FENCE.finditer(text):
        block = m.group(2)
        if MODULE.search(block) and "endmodule" in block:
            out.append(block)
    return out


def last_messages(case):
    """Every run's final message, per arm, recovered from llm grader evidence."""
    for arm, runs in case.get("arms", {}).items():
        for i, run in enumerate(runs or []):
            text = next(
                (g["evidence"] for g in run.get("graders", []) if g.get("evidence")),
                None,
            )
            yield arm, i + 1, text


def lint(source, workdir, name):
    """Lint one concatenated source. Returns (codes, raw, inconclusive)."""
    # SystemVerilog constructs need the .sv extension for Verilator to parse.
    ext = ".sv" if re.search(r"\b(always_ff|always_comb|logic|typedef enum)\b", source) else ".v"
    path = os.path.join(workdir, name + ext)
    with open(path, "w") as fh:
        fh.write(source)
    proc = subprocess.run(
        ["verilator", "--lint-only", "-Wall", "-Wno-fatal", "-Wno-DECLFILENAME", path],
        capture_output=True, text=True,
    )
    raw = proc.stdout + proc.stderr
    # A snippet that references a module it did not include is an artefact of
    # extraction, not a defect in the RTL. Same for a response that showed the
    # same module twice (before/after). Neither is a verdict.
    if "Cannot find file containing module" in raw or "already defined" in raw:
        return set(), raw, True
    codes = {m.group(1) or m.group(2) or "ERROR" for m in CODE.finditer(raw)}
    return codes, raw, False


def main(argv):
    if not shutil.which("verilator"):
        print("verilator not installed (apt-get install verilator)", file=sys.stderr)
        return 2
    if len(argv) < 2:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        print("usage: lint-generated-rtl.py <results.json> [...]", file=sys.stderr)
        return 2

    failures = 0
    linted = 0
    workdir = tempfile.mkdtemp(prefix="vlint-")
    try:
        for results_path in argv[1:]:
            with open(results_path) as fh:
                data = json.load(fh)
            print(f"\n=== {os.path.basename(results_path)} ===")
            for case in data.get("cases", []):
                rows = []
                for arm, idx, text in last_messages(case):
                    if text is None:
                        rows.append((arm, idx, "no llm-grader evidence to extract from", None))
                        continue
                    blocks = complete_modules(text)
                    if not blocks:
                        rows.append((arm, idx, "no complete module in final message", None))
                        continue
                    # Concatenate, so a helper module defined alongside the top
                    # level resolves. If the response showed the same module
                    # twice - before and after a fix - that collides, so fall
                    # back to the last one, which is the version being proposed.
                    stem = f"{case['name']}_{arm}_{idx}"
                    codes, raw, inconclusive = lint("\n\n".join(blocks), workdir, stem)
                    if inconclusive and "already defined" in raw and len(blocks) > 1:
                        codes, raw, inconclusive = lint(blocks[-1], workdir, stem + "_last")
                    linted += 1
                    if inconclusive:
                        rows.append((arm, idx, "inconclusive (partial snippet)", None))
                        continue
                    blocking = sorted(codes & (BLOCKING | {"ERROR"}))
                    advisory = sorted(codes & ADVISORY)
                    other = sorted(codes - BLOCKING - ADVISORY - {"ERROR"})
                    if blocking:
                        failures += 1
                    verdict = "FAIL " + " ".join(blocking) if blocking else "clean"
                    extra = ", ".join(filter(None, [
                        ("advisory: " + " ".join(advisory)) if advisory else "",
                        ("other: " + " ".join(other)) if other else "",
                    ]))
                    rows.append((arm, idx, verdict, extra or None))

                if all(r[2] == "no complete module in final message" for r in rows):
                    continue
                print(f"\n  {case['name']}")
                for arm, idx, verdict, extra in rows:
                    line = f"    {arm:<8} run {idx}  {verdict}"
                    if extra:
                        line += f"   [{extra}]"
                    print(line)
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    print(f"\n{linted} source(s) linted, {failures} with blocking defects")
    if linted == 0:
        # Silence here means the extraction found nothing, not that the RTL was
        # fine. The usual cause is an agent that wrote its module to a file
        # instead of inlining it in the reply, which happens as soon as Write
        # is granted.
        print("nothing was linted - no complete module appeared in any final "
              "message. Check whether the agent wrote its RTL to a file "
              "instead of inlining it.", file=sys.stderr)
        return 2
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
