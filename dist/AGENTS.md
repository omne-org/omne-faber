---
name: omne-faber-agents
description: Skill directory and pipe index for omne-faber (SDE workflow distro)
type: user
version: 2
---

# omne-faber

Software-engineering workflow distro for omne. Drives features end-to-end — plan, code, tests, adversarial review, human approval — as a DAG executed by the kernel runtime. Loaded by the kernel bootloader in a single hop: `CLAUDE.md @imports .omne/dist/AGENTS.md`.

## Skills

| Skill | Purpose |
| --- | --- |
| plan | Produce an implementation plan at `lib/docs/inter/plan-{feature_name}.md` |
| implement | Write code and tests from the plan (uses opus) |
| fix-loop | Iterate on failing tests until they pass or max-iterations is hit |
| review-security | Adversarial security review of the diff |
| review-correctness | Logic and edge-case review of the diff |
| synthesize-review | Merge reviewer findings into a single report for human approval |

## Pipes

| Pipe | Purpose |
| --- | --- |
| feature | plan -> implement -> tests -> fix-loop -> fanout review -> synthesis -> human approval |

## Conventions

**Artifact paths.** Every cross-skill handoff lives under `lib/docs/inter/`. Naming is deterministic so downstream nodes can address inputs by path:

- `plan-{feature_name}.md`
- `review-security-{feature_name}.md`
- `review-correctness-{feature_name}.md`
- `review-synthesis-{feature_name}.md`

`{feature_name}` comes from `$OMNE_INPUT_FEATURE_NAME`, which the kernel injects into every AI node from the `--input feature_name=...` flag passed to `omne run`.

**Sentinels used by this distro.** `fix-loop` terminates on the reserved `ALL_TASKS_COMPLETE` token. Any skill may emit `BLOCKED` as a complete line to abort on ambiguity or missing preconditions. Both tokens are kernel-reserved — this distro does not define its own.

**Gates.** The `feature` pipe's `approve` node registers the `human-approval` gate, which runs `dist/hooks/human-approval.ps1` (Windows) or `dist/hooks/human-approval.sh` (Linux/Mac). In v1 the hook exits 0 as a no-op checkpoint — kernel v0.2.x has no `omne signal` verb (deferred post-v1), so "real parking" is not available. The human reviews the worktree outside omne and merges manually. A future kernel release is expected to add signal-based parking; the distro will update when it lands.

**Environment contract.** The kernel injects environment variables non-uniformly across node kinds in v0.2.x:

- **Gate hooks** receive `OMNE_RUN_ID`, `OMNE_NODE_ID`, `OMNE_GATE_NAME`, `OMNE_VOLUME_ROOT`.
- **Bash nodes** receive `OMNE_INPUT_*` keys set on the run.
- **AI nodes (skill invocations)** currently receive **no omne-specific env vars** in v0.2.x — the kernel does not forward `OMNE_INPUT_*` or volume-root vars into the `claude -p` subprocess. Tracked as an upstream gap; skill bodies that reference `$OMNE_INPUT_FEATURE_NAME` are written in anticipation of the kernel fix and do not resolve on v0.2.x.

@.omne/core/skills/omne.md
