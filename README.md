# omne-faber

Reference software-engineering workflow distro for [omne](https://github.com/omne-org/omne). Ships one DAG pipe that drives a feature from plan through human approval.

## Requirements

- `omne-cli` **v0.2.0 or newer** (`cargo install --locked omne-cli` or download from [omne-cli releases](https://github.com/omne-org/omne-cli/releases))
- `claude` CLI on `PATH` (Claude Code)

## Install into a volume

From the root of any repo you want to drive with omne:

```
omne init omne-faber
```

This downloads the latest faber release tarball, extracts `dist/` into the volume's `.omne/dist/`, stamps `CLAUDE.md` with the bootloader `@import`, and records the pinned version in `.omne/cfg/manifest.json`.

## Run the feature pipe

```
omne run feature --input feature_name=<kebab-case-name>
```

The runner prints `run_id=<value>` on its first stdout line. Poll progress with `omne status <run_id>`. Event logs live at `.omne/var/runs/<run_id>/events.jsonl`.

## What's in the box

### Pipe

| Pipe | Flow |
| --- | --- |
| `feature` | `plan` → `implement` → `run-tests` (bash) → `fix-loop` (loop) → fanout (`review-security`, `review-correctness`) → `synthesize` → `approve` (human gate) |

### Skills

| Skill | Purpose | Model |
| --- | --- | --- |
| `plan` | Produce implementation plan at `lib/docs/inter/plan-{feature_name}.md` | sonnet |
| `implement` | Write code + tests from the plan | opus |
| `fix-loop` | Iterate on failing tests until green (terminator `ALL_TASKS_COMPLETE`, max 5 iterations) | sonnet |
| `review-security` | Adversarial security review of the diff | sonnet |
| `review-correctness` | Logic and edge-case review of the diff | sonnet |
| `synthesize-review` | Merge reviewer findings; re-run at the human-approval gate | sonnet |

### Gates

| Hook | Triggers | Effect |
| --- | --- | --- |
| `human-approval` | `approve` node, after `synthesize-review` recaps findings | Hook exits non-zero → run parks until operator runs `omne signal <run_id> human-approval` |

## Handoff contract

Cross-skill communication uses `lib/docs/inter/` inside the run's worktree:

- `plan-{feature_name}.md` — written by `plan`, read by `implement` and `fix-loop`
- `review-security-{feature_name}.md` — written by `review-security`, read by `synthesize-review`
- `review-correctness-{feature_name}.md` — written by `review-correctness`, read by `synthesize-review`
- `review-synthesis-{feature_name}.md` — written by `synthesize-review`

`{feature_name}` is the kernel-injected `$OMNE_INPUT_FEATURE_NAME` env var, sourced from `--input feature_name=...`.

## Layout

```
dist/
  AGENTS.md             # 1-hop boot target; imported by volume's CLAUDE.md
  skills/
    plan.md
    implement.md
    fix-loop.md
    review-security.md
    review-correctness.md
    synthesize-review.md
  pipes/
    feature.md          # DAG with loop + fanout
  hooks/
    human-approval.ps1
    human-approval.sh
```

## v1 limitations

- One pipe (`feature`). `hotfix`, `refactor`, and `pr-review` pipes are deferred to post-v1.
- `fix-loop` runs with `fresh_context: true` only — kernel has not yet shipped `claude --resume` support.
- No signed release artifacts (Sigstore / cosign deferred to post-v1).
- One feature at a time per volume — parallel runs of the same pipe with different `feature_name` inputs work, but `lib/docs/inter/` file names are keyed on feature_name only, so concurrent runs on the same feature collide.

## Contributing

See [CHANGELOG.md](CHANGELOG.md) for version history. File issues or feature requests at the [issue tracker](https://github.com/omne-org/omne-faber/issues).
