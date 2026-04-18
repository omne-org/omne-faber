---
name: plan
description: Produce an implementation plan for a feature, covering test scenarios and the exact file list the implement skill must write.
allowed_tools:
  - Read
  - Grep
  - Bash
  - Write
context: |
  Reads: the current worktree's `src/`, `tests/`, and `lib/cfg/` to learn
  the codebase shape and any volume-scoped conventions.
  Writes: `lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md` — the sole
  handoff artifact. The implement skill reads this exact path. If the
  path parity breaks, the pipe breaks. Use the env var literally; do
  not interpolate into a different filename.
---

# plan

You are the planning step of the feature pipe. The feature name is in
`$OMNE_INPUT_FEATURE_NAME`. Your single deliverable is a plan file at
`lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md`.

## When this skill applies

The feature pipe's `plan` node invoked you. The user has not written
code yet. No other planning document exists for this feature.

## Inputs

- `$OMNE_INPUT_FEATURE_NAME` — short kebab-case identifier for the
  feature. Use it in file paths only, not in narrative prose.
- `src/` — existing source. Read the top-level files and any module
  adjacent to the feature's subject matter. Do not read the entire
  tree.
- `tests/` — existing tests. Identify the test runner and the naming
  convention (e.g. `tests/foo_test.rs` vs `tests/test_foo.py`).
- `lib/cfg/` — volume-scoped config. If absent, skip. If present, scan
  for feature-relevant settings (e.g. API endpoints, feature flags).

## Outputs

One file: `lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md`.

Required sections, in order:

1. `## Summary` — one paragraph: what the feature does and why.
2. `## Test scenarios` — bulleted list. Each bullet is one scenario in
   the form "Given X, when Y, then Z." Cover happy path, at least one
   edge case, at least one error path. These are the assertions the
   implement skill will encode in tests.
3. `## Files to write` — explicit list of every source and test file
   the implement skill must create or modify. For each entry: the
   path, one line on the responsibility, and (for modifications) a
   one-line summary of the change.
4. `## Non-goals` — bulleted list of things explicitly out of scope.
   Prevents implement from overreaching.
5. `## Open questions` — if any ambiguity remains that cannot be
   resolved from `src/`/`tests/`/`lib/cfg/`, list it here. If the list
   is non-empty, implement will emit the reserved blocked sentinel.

Keep the plan under 400 words. A longer plan is a signal that the
feature should be split.

## What NOT to do

- Do not write source code. Plan only.
- Do not reference files outside the worktree.
- Do not emit any reserved sentinel token. You are not a loop node and
  you are not blocked — you write a plan.
- Do not mention `$OMNE_INPUT_FEATURE_NAME` in the plan's prose. Use
  the literal feature name instead. The env var is for path
  construction only.
- Do not create placeholder files under `src/` or `tests/`. Writing
  those is the next skill's job.

## Termination

Write the plan file. Exit. The runner records node completion from
your subprocess exit, not from a sentinel.
