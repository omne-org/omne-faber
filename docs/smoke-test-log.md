# Smoke test log — feature pipe

**Status: DEFERRED (kernel blocker).**

## Environment

- `omne-cli`: 0.2.0 (crates.io; installed via `cargo install --locked omne-cli --force`)
- `claude`: 2.1.113 (Claude Code)
- `omne-faber`: v2.0.0 (GitHub Release; tarball top-level `dist/`)
- Platform: Windows 11, `E:\dev\Productivity\Git\bin\bash.exe` (via `CLAUDE_CODE_GIT_BASH_PATH`)
- Test volume: `omne-faber/.smoke/add-hello/` (throwaway Rust crate, committed once)

## Timeline

### Attempt 1 — `feature-01kpfntqeej7vhn935kc0tm9vn` (aborted)

Failure: git `worktree add --detach` on an unborn branch — `fatal: invalid reference: HEAD`.

Cause: `cargo init` creates a git repo with zero commits. The kernel's worktree allocator requires a resolvable `HEAD`.

Fix: committed the scaffold in the test volume before dispatch.

### Attempt 2 — `feature-01kpfnv7m8dxv4z35x0xe61pth` (aborted on `plan`)

Failure: `error.kind: crash` on the first AI node.

Message:
```
Claude Code on Windows requires git-bash (https://git-scm.com/downloads/win).
If installed but not in PATH, set environment variable pointing to your bash.exe,
similar to: CLAUDE_CODE_GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe
```

Fix: exported `CLAUDE_CODE_GIT_BASH_PATH=E:\dev\Productivity\Git\bin\bash.exe` before dispatch. (This is a Claude Code host requirement on Windows — not an omne bug.)

### Attempt 3 — `feature-01kpfnwvm97771jwvjt1r85f0a` (aborted on `fix-loop` / max_iterations_exceeded)

`plan`, `implement`, `run-tests` all fired `node.completed` in sequence. `fix-loop` entered its loop and ran five iterations, each with zero agent output, then failed with `max_iterations_exceeded`.

Root cause investigation:
- `.omne/var/runs/<run_id>/nodes/plan.out` contents: `/plan isn't available in this environment.`
- `.omne/var/runs/<run_id>/nodes/implement.out`: empty.
- `.omne/var/runs/<run_id>/nodes/fix-loop.out`: only `=== omne:iteration:N ===` markers, no agent output between them.

Every AI node received a prompt of the form `/plan`, `/implement`, `/fix-loop` (slash-command syntax). Claude Code reported the commands were unavailable. The earlier nodes recorded `node.completed` because claude exited cleanly — the kernel cannot distinguish a zero-work run from a productive one.

## Root cause (kernel)

Three-part mismatch in `omne-cli` v0.2.0, all tracked under [omne-cli#21](https://github.com/omne-org/omne-cli/issues/21):

1. **Prompt format sends slash commands.** `omne-cli/src/executor.rs:324` builds AI prompts as `format!("/{command}")`. Slash commands resolve against `.claude/commands/<name>.md`, which the kernel never wires.

2. **Skill linker only handles directory layout.** `omne-cli/src/claude_skills.rs:97` filters out non-directory entries with `if !src.is_dir() { continue; }`. File-based skills (`dist/skills/<name>.md` — the layout the kernel plan specs at line 286: *"every `command` name resolves to `dist/skills/<name>.md` or `core/skills/<name>.md`"*) are silently skipped. Even if they were linked, they land under `.claude/skills/`, not `.claude/commands/`, so `/plan` still wouldn't resolve.

3. **AI nodes receive no omne-specific env vars.** `omne-cli/src/executor.rs:266` (`run_ai`) calls `build_spawn_opts` at line 656, which produces a `SpawnOpts` with no env-var hook; `claude_proc::spawn` forwards only inherited process env. The kernel sets `OMNE_RUN_ID` / `OMNE_VOLUME_ROOT` only for gate hooks (line 892-895) and `OMNE_INPUT_*` only for bash nodes (line 227-230). Skills that reference `$OMNE_INPUT_FEATURE_NAME` to construct handoff paths therefore get an empty string — the path `lib/docs/inter/plan-.md` would collide across concurrent features, but more importantly the skill cannot know what feature it is working on.

Net effect: a distro built to the kernel plan's specified file-based skill layout ships no usable AI nodes under v0.2.0. All three gaps must close before the pipe can run.

## Faber status

- File-based skill files (`dist/skills/plan.md` et al.) match kernel plan R2 / R17 and kernel plan line 286.
- v2 DAG, frontmatter, loop, fanout, and gate configuration are all accepted by `omne validate` (the v2 pipe schema validator passes cleanly on the scaffolded volume).
- Distro content is not the blocker. Smoke failure is kernel-side wiring.

## Decision

Unit 6 is **deferred** pending kernel fix tracked in [omne-cli#21](https://github.com/omne-org/omne-cli/issues/21).

Re-run this smoke once the kernel:

- wires file-based skills to `.claude/commands/<name>.md` (or changes the `command:` prompt form to embed skill bodies directly), AND
- injects `OMNE_INPUT_*` + `OMNE_RUN_ID` + `OMNE_VOLUME_ROOT` into AI node subprocesses the way it already does for bash nodes and gate hooks.

When the kernel patch lands, faber tags v2.0.1 with the content fixes from this review (hook no-op semantics, README requirement bump, removed dead frontmatter, detached-worktree git-diff correction).
