---
name: synthesize-review
description: Merge the security and correctness reviewer outputs into a single summary for the human approver. When reviewers disagree, list both findings verbatim; do not pick a winner.
allowed_tools:
  - Read
  - Write
context: |
  Reads: `lib/docs/inter/review-security-$OMNE_INPUT_FEATURE_NAME.md`
  and `lib/docs/inter/review-correctness-$OMNE_INPUT_FEATURE_NAME.md`.
  Writes:
  `lib/docs/inter/review-synthesis-$OMNE_INPUT_FEATURE_NAME.md`. The
  subsequent `approve` gate reads this synthesis; the human operator
  approves or rejects based on it.
---

# synthesize-review

You are the fanout gather step. Two reviewers ran in parallel. Your
job is to produce one document the human can read in under two
minutes to make an approval decision.

## When this skill applies

The feature pipe's `synthesize` node invoked you. Under
`trigger_rule: one_success` the node can fire with only one reviewer
present — handle missing-input gracefully.

## Inputs

- `lib/docs/inter/review-security-$OMNE_INPUT_FEATURE_NAME.md` — may
  be absent if that reviewer failed.
- `lib/docs/inter/review-correctness-$OMNE_INPUT_FEATURE_NAME.md` —
  may be absent if that reviewer failed.

At least one of the two exists; the pipe's trigger rule guarantees
it. If a file is missing, note "reviewer unavailable" in the
synthesis; do not fabricate its findings.

## Outputs

One file:
`lib/docs/inter/review-synthesis-$OMNE_INPUT_FEATURE_NAME.md`.

Required sections, in order:

1. `## Overall verdict` — one line: `READY_FOR_APPROVAL`,
   `CHANGES_REQUESTED`, or `REJECT`. Derived by the rule in the next
   section.
2. `## Highest-severity items` — the set of `critical` and `high`
   findings from either reviewer, deduplicated across reviewers by
   (file, line range, issue gist). Each item shows the source
   reviewer(s) in brackets, e.g. `[security]`, `[correctness]`, or
   `[security, correctness]` when both raised it.
3. `## Disagreements` — any finding where one reviewer flagged an
   issue and the other explicitly accepted the same code path. List
   both findings verbatim. Do not reconcile. Do not pick a winner.
   The human operator decides.
4. `## Lower-severity items` — `medium`, `low`, and `info` findings,
   grouped by reviewer, terse bullets only.
5. `## Scenario coverage` — copy the correctness reviewer's audit
   table if present; otherwise write "coverage audit unavailable".

## Verdict derivation

- Any reviewer verdict of `REJECT` → overall `REJECT`.
- Any unresolved `critical` or `high` severity finding → overall
  `CHANGES_REQUESTED`.
- All reviewers `ACCEPT` or `ACCEPT_WITH_CONDITIONS` with only
  `medium`/`low`/`info` findings → overall `READY_FOR_APPROVAL`.
- If only one reviewer's file exists, downgrade `READY_FOR_APPROVAL`
  to `CHANGES_REQUESTED` and note the reviewer gap in the synthesis.

## What NOT to do

- Do not summarize by averaging. Disagreement is data; preserve it.
- Do not drop a finding because the other reviewer disagrees.
- Do not add your own opinions. You are a reducer, not a third
  reviewer.
- Do not modify source code.
- Do not emit any reserved sentinel token. Exit normally after
  writing the synthesis file.

## Termination

Write the synthesis file. Exit. The subsequent `approve` gate in the
pipe pauses for the human.
