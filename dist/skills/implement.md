---
name: implement
description: Read the feature plan and produce the source files and tests it specifies. Emit the reserved blocked sentinel on ambiguity rather than guessing.
allowed_tools:
  - Read
  - Grep
  - Edit
  - Write
  - Bash
context: |
  Reads: `lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md` (written by
  the plan skill). Also reads `src/` and `tests/` to conform to
  existing code style.
  Writes: files under `src/` and `tests/` exactly as enumerated in the
  plan's "Files to write" section. Does not touch `lib/docs/inter/`.
---

# implement

You are the implementation step. The plan file at
`lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md` is your contract.
Follow it. Do not deviate.

## When this skill applies

The feature pipe's `implement` node invoked you. A plan file exists
at the path above. If it does not exist, that is a pipe wiring bug —
emit the reserved blocked sentinel as described under "Termination".

## Inputs

- `lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md` — the full plan.
  Read it first. Read it completely.
- `src/` — existing sources. Match their style (formatting, import
  order, error handling, naming).
- `tests/` — existing tests. Match the runner and file-naming
  convention already in use.

## Outputs

Every file listed in the plan's `## Files to write` section, created
or modified to match the plan's responsibility description. Test
files must encode every scenario from the plan's `## Test scenarios`
section as an actual assertion. No scenario may be silently skipped.

Do not create files the plan does not list. Do not modify files the
plan does not list.

## What NOT to do

- Do not edit the plan file. It is a read-only input.
- Do not run the test suite. The next node (`run-tests`) does that.
- Do not write to `lib/docs/inter/`. That directory is for skill
  handoffs; implement writes only to the worktree code.
- Do not invent features. If the plan is silent on a detail, that is
  a plan defect, not a license to improvise.
- Do not quote reserved sentinel tokens in source comments or test
  names. Sentinel scanning runs on reconstructed assistant text; a
  stray line-complete match aborts the node.

## Termination

- On success: finish writing files and exit. The runner records node
  completion.
- On ambiguity you cannot resolve from the plan, `src/`, `tests/`, or
  `lib/cfg/`: emit the reserved blocked token as a complete trimmed
  line on stdout, then exit. The runner records the node as failed
  with kind `blocked` and halts the pipe. Do not speculate; halting
  is the correct behavior. State the ambiguity once in a short line
  before the sentinel so the human operator has context. The
  sentinel itself is `BLOCKED`.
