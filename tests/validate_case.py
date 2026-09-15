"""Validate one eval case.yaml against the schema `claude plugin eval` enforces.

Reimplemented here rather than shelled out to the CLI because the CLI only
validates as part of a real (paid, slow) run. Keep this in step with the
binary's schema if it moves - `claude plugin eval --help` names the version.
"""
import os
import sys

import yaml

GRADER_FIELDS = {
    "regex": ({"name", "pattern"}, {"target", "flags", "match", "weight", "arm", "type"}),
    "tool_order": ({"name", "before", "after"}, {"weight", "arm", "type"}),
    "tool_used": ({"name", "tool"}, {"input_match", "min", "max", "weight", "arm", "type"}),
    "file_exists": ({"name", "path"}, {"exists", "weight", "arm", "type"}),
    "llm": ({"name", "criteria"}, {"focus", "weight", "arm", "type"}),
    "baseline": ({"name", "baseline_file", "criteria"}, {"weight", "arm", "type"}),
}
TARGETS = {"trace", "last_message", "files", "mock_calls"}
ARMS = {"with-only", "both"}

errors = []


def err(msg):
    errors.append(msg)


path = os.environ["CASE_FILE"]
with open(path) as fh:
    try:
        case = yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        print(f"YAML parse failed: {exc}")
        sys.exit(1)

if not isinstance(case, dict):
    print("case.yaml must be a YAML object")
    sys.exit(1)

sv = case.get("schema_version")
if not isinstance(sv, str):
    err('missing required field schema_version (e.g. "1.0")')
elif not sv.split(".")[0].isdigit():
    err(f'schema_version "{sv}" is not a valid version string')
elif int(sv.split(".")[0]) > 1:
    err(f'schema_version "{sv}" requires a newer Claude Code')

if not case.get("name"):
    err("missing required field name")

expected_name = os.path.basename(os.path.dirname(path))
if case.get("name") and case["name"] != expected_name:
    err(f'name "{case["name"]}" does not match its directory "{expected_name}"')

execution = case.get("execution", {})
if not isinstance(execution, dict):
    err("execution must be a mapping")
    execution = {}

prompt = execution.get("prompt")
if not prompt or not str(prompt).strip():
    err("no case definition: execution.prompt is empty (or write it to prompt.md)")
elif "TODO:" in str(prompt):
    err("the prompt is still the blank `init` template")

for field, limit in (("max_turns", 200), ("timeout_seconds", 3600)):
    if field in execution:
        v = execution[field]
        if not isinstance(v, int) or v <= 0 or v > limit:
            err(f"execution.{field} must be an integer in 1..{limit}, got {v!r}")

runs = case.get("runs", 3)
if not isinstance(runs, int) or runs <= 0 or runs > 50:
    err(f"runs must be an integer in 1..50, got {runs!r}")

graders = case.get("graders")
if not isinstance(graders, list) or not graders:
    err("graders must be a non-empty list")
    graders = []

seen = set()
for i, g in enumerate(graders):
    where = f"graders[{i}]"
    if not isinstance(g, dict):
        err(f"{where} must be a mapping")
        continue
    gtype = g.get("type")
    if gtype not in GRADER_FIELDS:
        err(f"{where}: unknown grader type {gtype!r} (expected one of {', '.join(sorted(GRADER_FIELDS))})")
        continue
    name = g.get("name")
    if name in seen:
        err(f'duplicate grader name "{name}"')
    seen.add(name)

    required, optional = GRADER_FIELDS[gtype]
    missing = required - set(g)
    if missing:
        err(f"{where} ({gtype}): missing {', '.join(sorted(missing))}")
    unknown = set(g) - required - optional
    if unknown:
        err(f"{where} ({gtype}): unknown field(s) {', '.join(sorted(unknown))}")

    if "arm" in g and g["arm"] not in ARMS:
        err(f"{where}: arm must be one of {', '.join(sorted(ARMS))}")
    for key in ("target", "focus"):
        if key in g and not (g[key] in TARGETS or isinstance(g[key], dict)):
            err(f"{where}: {key} must be one of {', '.join(sorted(TARGETS))} or a {{source: file, path: ...}} mapping")
    if gtype == "regex":
        match = g.get("match", "contains")
        if match not in ("contains", "not_contains") and not (
            isinstance(match, str) and match.startswith("count:") and match[6:].isdigit()
        ):
            err(f"{where}: match must be contains | not_contains | count:N")
        import re
        try:
            re.compile(g.get("pattern", ""))
        except re.error as exc:
            err(f"{where}: pattern is not a valid regex: {exc}")
    if gtype == "llm" and "TODO:" in str(g.get("criteria", "")):
        err(f'{where}: criteria is still the blank `init` template')

if errors:
    for e in errors:
        print(e)
    sys.exit(1)
sys.exit(0)
