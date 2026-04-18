---
name: feature
version: 1
default_model: claude-sonnet-4-6
inputs:
  feature_name: { type: string, required: true }
nodes:
  - id: plan
    command: plan

  - id: implement
    depends_on: [plan]
    command: implement
    model: claude-opus-4-6

  - id: run-tests
    depends_on: [implement]
    bash: "cargo test"

  - id: fix-loop
    depends_on: [run-tests]
    loop:
      command: fix-loop
      until: ALL_TASKS_COMPLETE
      max_iterations: 5
      fresh_context: true

  - id: review-security
    depends_on: [fix-loop]
    command: review-security

  - id: review-correctness
    depends_on: [fix-loop]
    command: review-correctness

  - id: synthesize
    depends_on: [review-security, review-correctness]
    trigger_rule: one_success
    command: synthesize-review

  - id: approve
    depends_on: [synthesize]
    command: synthesize-review
    gate: human-approval
---

# Feature Pipe

Drives a feature from initial plan through a human-approval gate. The DAG fans out two independent reviewers after a bounded fix-loop, synthesizes their findings, and parks the run at a human gate for the final sign-off.

## Inputs

| Name | Type | Required | Example |
| --- | --- | --- | --- |
| `feature_name` | string | yes | `add-auth-middleware` |

The runner exports this as `OMNE_INPUT_FEATURE_NAME` into every node subprocess.

## Flow

Every AI node runs as `claude -p --output-format stream-json` in the run's worktree at `.omne/wt/<run_id>/`. Reconstructed assistant text lands at `.omne/var/runs/<run_id>/nodes/<node_id>.out`. Skills are free to also write human-readable artifacts into the worktree at `lib/docs/inter/` so later nodes and the user can read them.

1. **plan** (`command: plan`, sonnet) — reads the feature name, drafts an implementation plan. Captures to `nodes/plan.out`; writes the plan artifact to `lib/docs/inter/plan-<feature_name>.md`.
2. **implement** (`command: implement`, opus) — consumes the plan, edits `src/` and `tests/` inside the worktree. Captures a change summary to `nodes/implement.out`. Model override to opus for code-heavy work; the rest of the pipe inherits `default_model` (sonnet).
3. **run-tests** (`bash: cargo test`) — runs the Rust test suite directly in the worktree. No model, no prompt; exit code drives success or failure. Stdout/stderr tail lands at `nodes/run-tests.out`.
4. **fix-loop** (`loop` over `command: fix-loop`, sonnet) — iterates on failing tests until the agent emits `ALL_TASKS_COMPLETE` as a complete trimmed line, `max_iterations: 5` is exhausted (→ `node.failed{max_iterations_exceeded}`), or the agent emits `BLOCKED` (→ `node.failed{blocked}`). Each iteration is a fresh claude session. Per-iteration captures concatenate into `nodes/fix-loop.out`.
5. **review-security** and **review-correctness** (parallel `command`s, sonnet) — both depend only on `fix-loop`, so the scheduler dispatches them concurrently once the loop terminates. Each writes its review to `lib/docs/inter/review-security-<feature_name>.md` and `lib/docs/inter/review-correctness-<feature_name>.md` respectively. Node captures at `nodes/review-security.out` and `nodes/review-correctness.out`.
6. **synthesize** (`command: synthesize-review`, `trigger_rule: one_success`) — joins the fanout. `one_success` means the synthesizer runs as long as at least one reviewer succeeded; a single reviewer crash does not wedge the pipe. Writes the merged judgment to `lib/docs/inter/review-synthesis-<feature_name>.md` and captures to `nodes/synthesize.out`.
7. **approve** (`command: synthesize-review`, `gate: human-approval`) — re-runs the same synthesize skill as a recap, then runs the `human-approval` gate hook. The v1 hook exits 0 as a no-op checkpoint (no `omne signal` in kernel v0.2.x), so `approve` fires `gate.passed` immediately after the recap and the run terminates `pipe.completed`. The human reviews the worktree manually after the run ends.

## Outputs

Terminal artifacts produced by a completed run:

- **Worktree changes** under `.omne/wt/<run_id>/src/` and `.omne/wt/<run_id>/tests/` — the actual feature implementation and its tests. The worktree persists after the run; merge or cherry-pick manually.
- **Planning artifact**: `lib/docs/inter/plan-<feature_name>.md`
- **Review artifacts**: `lib/docs/inter/review-security-<feature_name>.md`, `lib/docs/inter/review-correctness-<feature_name>.md`, `lib/docs/inter/review-synthesis-<feature_name>.md`
- **Per-run event log**: `.omne/var/runs/<run_id>/events.jsonl`
- **Per-node captures**: `.omne/var/runs/<run_id>/nodes/<node_id>.out` for every node above
- **Pending gate**: the `approve` node parks at the `human-approval` hook; the run stays open until the hook exits 0 (or the 60s timeout trips).

## Running

```
omne run feature --input feature_name=<name>
```

`claude` must be on `PATH` — the AI nodes spawn `claude -p --output-format stream-json` and the runner's preflight check aborts with `host_missing` before any state is written if `claude --version` fails.

From inside Claude Code, dispatch through the Bash tool with `run_in_background: true`; `omne run` prints `run_id=<value>` as its first stdout line before going long-running, and the session would otherwise freeze for the full pipe duration.

## Notes

**`approve` reuses `synthesize-review`.** The last node carries `command: synthesize-review` with a `gate: human-approval` modifier, not a standalone `prompt:` stub. A stub prompt node would satisfy the schema but exists only to hang a gate off; re-running synthesize-review produces a fresh recap at the exact moment the gate fires. In v1 this recap is the only human-facing artifact before the run completes (the hook is a no-op), so the redundant call pays for itself.

**Human-approval gate is a no-op in v1.** Kernel v0.2.x has no `omne signal` verb. The hook exits 0 immediately after the recap; the run ends `pipe.completed` rather than parking. Operators review the worktree (at `.omne/wt/<run_id>/`) manually. When the kernel ships `omne signal` in a future release, this distro will update the hook to exit non-zero and document the release step.

**`fresh_context: true` is the only form available.** Kernel v1 defers the `claude --resume` session-resume story (see Unit 0 spike in the kernel plan). Until the spike unblocks `fresh_context: false`, the validator rejects it. Each iteration of `fix-loop` therefore starts from a clean session and must re-read whatever state it needs from the worktree; the `fix-loop` skill is written with that assumption.

**Schema deltas from pre-v2.** This pipe uses `command:` references into `dist/skills/` and a flat DAG. The old `agent:`, `advances_stage:`, `covers_stages:`, and `stages` vocabulary are rejected by the v2 schema and do not appear here.
