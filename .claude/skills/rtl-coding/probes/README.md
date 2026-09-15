# Probes

Scratch experiments, not part of the suite. They run with `--eval-dir probes`,
so a normal `claude plugin eval` never sees them.

## selfcheck-off / selfcheck-on

Asks whether the skill should lint its own generated RTL with Verilator before
returning it. Both arms share a prompt with genuine latch and width risk (a
parameterised round-robin arbiter). `selfcheck-on` simulates the skill change
through `append_system_prompt`, so the experiment does not have to modify the
skill under test.

**Status: could not be run.** Two blockers, both environmental:

1. The eval refuses a shell grant unless a sandbox backend is present
   (`apt install bubblewrap socat`), and inside a container the nested sandbox
   then fails anyway - `apply-seccomp: write /proc/self/uid_map: Operation not
   permitted` - so the treatment arm never reached Verilator.
2. `--allow-tools` is a CLI-wide grant. It applies to every case in the run,
   overriding each case's own `allowed_tools`, so it handed `Write` to the
   control arm too. Both arms then wrote their module to a file instead of
   inlining it, which is a different behaviour from the one being measured.

To run this for real, use a host with a working sandbox backend, and give the
two arms separate invocations so the control never receives the shell grant:

```bash
claude plugin eval .claude/skills/rtl-coding --eval-dir probes \
  --case selfcheck-off --ablation none
claude plugin eval .claude/skills/rtl-coding --eval-dir probes \
  --case selfcheck-on --ablation none --allow-tools Bash Write
```

Then compare with `python3 tests/lint-generated-rtl.py <results.json>`, and
note that a `tool_used` grader on Bash only proves the call was attempted.
