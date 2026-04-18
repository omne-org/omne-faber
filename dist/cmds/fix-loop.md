---
name: fix-loop
description: Read the last test run's failure output and the plan, then make minimal edits to src/ or tests/ so tests pass. Terminates the loop by emitting the reserved terminator when green.
allowed_tools:
  - Read
  - Grep
  - Edit
  - Write
  - Bash
context: |
  Reads: `lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md` and the
  most recent test output captured by the preceding `run-tests` node
  (available via the worktree's test runner — re-run it if stdout is
  not otherwise at hand).
  Writes: surgical edits to `src/` and `tests/`. Never touches
  `lib/docs/inter/`.
---

# fix-loop

You are the body of a `loop:` node. Each iteration, the runner spawns
you with fresh context. Your job: inspect the current failing tests
and make the smallest change that moves the suite toward green.

## When this skill applies

The feature pipe's `fix-loop` node invoked you. Tests ran and did not
all pass. You iterate until they do, up to the pipe's
`max_iterations` ceiling.

## Inputs

- Failing test output. Re-run the suite yourself if you need the
  current failure list (use the same runner the plan specifies; if
  the plan is silent, infer from `tests/`).
- `lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md` — the original
  contract. Tests must match the plan's scenarios; code must match
  the plan's file list.
- `src/` and `tests/` — the code under repair.

## Outputs

Minimal edits to `src/` and `tests/`. Prefer:

1. Fixing the source if a test correctly encodes a plan scenario and
   the source fails it.
2. Fixing the test if the test drifts from the plan's scenario.
3. Leaving both alone if the failure is environmental (missing
   dependency, wrong CWD) — emit the blocked sentinel instead.

Do not rewrite large swaths. Do not refactor. Minimal diff only.

## What NOT to do

- Do not delete failing tests to make the suite pass. A deleted
  scenario is a silently dropped requirement.
- Do not modify the plan file.
- Do not write to `lib/docs/inter/`.
- Do not quote the termination token in prose, comments, code, test
  names, or error messages. The scanner matches on whole trimmed
  lines — emit it exactly once, at the end, as described below.

## Termination rule

This skill runs inside a loop. The loop needs a signal that you are
done. After your edits, re-run the tests. Then:

- If all tests pass: emit the terminator token `ALL_TASKS_COMPLETE`
  as a complete trimmed line on stdout and exit. The runner records
  the loop as completed cleanly.
- If tests still fail and you made progress (fewer failures, or a
  different failure): exit normally. The runner spawns the next
  iteration.
- If tests fail in a way you cannot repair from the plan — e.g. the
  plan's scenario contradicts itself, or the environment is broken:
  emit `BLOCKED` as a complete trimmed line on stdout and exit.

Emit `ALL_TASKS_COMPLETE` only on the exit where every test in the
suite passes. Do not emit it speculatively. Do not emit it on
non-terminal iterations. It is the single, authoritative terminator
for this loop and no other skill in the pipe emits it.
