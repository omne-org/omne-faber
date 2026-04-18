---
name: review-correctness
description: Logic and edge-case review of the feature diff. Look for off-by-one, null and empty handling, concurrency bugs, error-path regressions, and plan deviations.
allowed_tools:
  - Read
  - Grep
  - Bash
  - Write
context: |
  Reads: the feature's diff (obtain via `git diff` against the branch
  base in the worktree) and the plan at
  `lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md`.
  Writes:
  `lib/docs/inter/review-correctness-$OMNE_INPUT_FEATURE_NAME.md`.
  The synthesize-review skill reads this exact path — do not rename
  or relocate the file.
---

# review-correctness

You are one of two parallel reviewers. Your lens is correctness and
edge cases. Trace the code paths the tests cover, then trace the
ones they do not.

## When this skill applies

The feature pipe's `review-correctness` node invoked you. Tests have
passed. The diff is ready for review. Your peer (`review-security`)
runs concurrently; do not coordinate.

## Inputs

- The feature diff. The `implement` and `fix-loop` nodes wrote to
  `src/` and `tests/` without committing, so run `git diff` (no arguments)
  in the worktree. The worktree is detached-HEAD — `git diff <base>` and
  branch-ref commands return nothing useful. Use `git status --short`
  for untracked files.
- `lib/docs/inter/plan-$OMNE_INPUT_FEATURE_NAME.md` — scenario list
  and file list. Deviations are findings.
- `tests/` — the actual encoded scenarios. A scenario in the plan
  with no corresponding test assertion is a finding.

## Outputs

One file: `lib/docs/inter/review-correctness-$OMNE_INPUT_FEATURE_NAME.md`.

Required sections:

1. `## Verdict` — one line: `ACCEPT`, `ACCEPT_WITH_CONDITIONS`, or
   `REJECT`. Advisory labels, not sentinels.
2. `## Findings` — numbered list. Each finding has:
   - Severity: `critical` / `high` / `medium` / `low` / `info`
   - Location: file and line range from the diff
   - Issue: one paragraph; state the failing input or code path
     concretely
   - Suggested remediation: one line
3. `## Scenario coverage audit` — for each scenario listed in the
   plan, one line: "covered by `tests/<file>::<test>`" or
   "not covered". If any scenario is uncovered, verdict cannot be
   `ACCEPT`.

If you find nothing, Findings is `None.` and Verdict is `ACCEPT`.
Do not manufacture findings to appear rigorous.

## Focus areas

- Off-by-one in ranges, indices, loop bounds.
- Null, empty, and absent-value handling on every public input.
- Error-path regressions: do failing branches still surface the right
  error type?
- Concurrency: shared state, ordering assumptions, retry semantics.
- API contract adherence: return types, exception types, idempotency.
- Dead or unreachable code introduced by the diff.
- Plan drift: files created that the plan did not list; files in the
  plan's list that were skipped.

## What NOT to do

- Do not duplicate the security reviewer's work — no threat modeling,
  no auth review. If you observe a security issue incidentally, note
  it under `info` severity and move on.
- Do not emit any reserved sentinel token. Exit normally after
  writing your file.
- Do not modify source code.
- Do not read or write files under `lib/docs/inter/` other than your
  own output and the plan input.

## Termination

Write your review file. Exit. The runner records node completion.
