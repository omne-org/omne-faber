# Changelog

## v2.0.1 — 2026-04-18

### Changed

- **File-layout skills moved from `dist/skills/` to `dist/cmds/`.** Kernel v0.2.1 splits skill linking into two namespaces: `dist/cmds/<name>.md` links into `.claude/commands/<name>.md` (invoked via `/name` slash prompts), while `dist/skills/<name>/SKILL.md` stays as dir-layout auto-invoked skills. Under kernel v0.2.0 the file-layout entries were silently dropped by the linker; this release places them where the new router expects them.
- Migrated skills: `plan`, `implement`, `fix-loop`, `review-security`, `review-correctness`, `synthesize-review` (6 files). Git history preserved via `git mv`.
- `dist/pipes/feature.md` and release workflow updated to reference `dist/cmds/`.

### Requirements

- `omne-cli >= 0.2.1` (required — v0.2.0 cannot link the file-layout commands under the new path).

## v2.0.0 — 2026-04-17

Full rewrite against omne v2 kernel.

### Breaking

- **Agent concept removed.** `dist/agents/` is gone. Workflows reference reusable units via `command:` → `dist/cmds/<name>.md` (originally `dist/skills/<name>.md` in v2.0.0; see v2.0.1).
- **Stage ladder removed.** No `stages`, `advances_stage`, or `covers_stages` in any pipe or AGENTS.md. Progress is observable from `.omne/var/runs/<run_id>/events.jsonl`.
- **`context-map.md` retired.** Per-skill file-access guidance lives in each skill's `context:` frontmatter field.
- **Tarball top-level renamed** from `image/` (pre-v2 design) to `dist/`. Requires omne-cli v0.2.0+.

### Added

- `dist/skills/` — six v1 skills: `plan`, `implement`, `fix-loop`, `review-security`, `review-correctness`, `synthesize-review`. (Relocated to `dist/cmds/` in v2.0.1.)
- `dist/pipes/feature.md` — DAG with a bounded fix-loop, a two-way fanout review, a synthesis step, and a human-approval gate. Exercises the kernel's full v2 **schema** surface (command / bash / loop / gate / `trigger_rule: one_success`). Full-runtime integration is pending a kernel patch (see Known Limitations).
- `.github/workflows/release.yml` — tag-driven release, packages `dist/` as tarball top-level.

### Requirements

- `omne-cli >= 0.2.1` (once released; v0.2.0 is blocked on [omne-cli#21](https://github.com/omne-org/omne-cli/issues/21))
- Claude Code (`claude` CLI) on `PATH`; Windows also needs `CLAUDE_CODE_GIT_BASH_PATH`

### Known Limitations

- AI nodes unexecutable under `omne-cli v0.2.0`. The kernel links only directory-layout skills, dispatches commands as unresolvable slash prompts, and does not inject volume/input env vars into `claude -p` subprocesses. Tracked as [omne-cli#21](https://github.com/omne-org/omne-cli/issues/21). Full integration smoke (faber plan Unit 6) is deferred until the kernel patch lands. See [docs/smoke-test-log.md](docs/smoke-test-log.md).
- Human-approval gate is a no-op checkpoint in v1. The kernel has no `omne signal` verb (post-v1 deferred), so the hook exits 0 immediately after the synthesis recap; operators review the worktree manually.

### Migration

No in-place migration path from 0.1.x. The schema delta is total. Upgrading a volume: remove the old `.omne/dist/`, run `omne init omne-faber` to scaffold v2.
