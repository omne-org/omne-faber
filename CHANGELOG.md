# Changelog

## v2.0.0 — 2026-04-17

Full rewrite against omne v2 kernel.

### Breaking

- **Agent concept removed.** `dist/agents/` is gone. Workflows reference reusable units via `command:` → `dist/skills/<name>.md`.
- **Stage ladder removed.** No `stages`, `advances_stage`, or `covers_stages` in any pipe or AGENTS.md. Progress is observable from `.omne/var/runs/<run_id>/events.jsonl`.
- **`context-map.md` retired.** Per-skill file-access guidance lives in each skill's `context:` frontmatter field.
- **Tarball top-level renamed** from `image/` (pre-v2 design) to `dist/`. Requires omne-cli v0.2.0+.

### Added

- `dist/skills/` — six v1 skills: `plan`, `implement`, `fix-loop`, `review-security`, `review-correctness`, `synthesize-review`.
- `dist/pipes/feature.md` — DAG with a bounded fix-loop, a two-way fanout review, a synthesis step, and a human-approval gate. Exercises the kernel's full runtime surface (command / bash / loop / gate / `trigger_rule: one_success`).
- `.github/workflows/release.yml` — tag-driven release, packages `dist/` as tarball top-level.

### Requirements

- `omne-cli >= 0.2.0`
- Claude Code (`claude` CLI) on `PATH`

### Migration

No in-place migration path from 0.1.x. The schema delta is total. Upgrading a volume: remove the old `.omne/dist/`, run `omne init omne-faber` to scaffold v2.
