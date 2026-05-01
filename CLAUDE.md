# CLAUDE.md — interface

Instructions for Claude Code sessions in this repo.

## What this repo is

Interface is the user-facing layer of the Orthon framework — UI, dashboards, and any orchestration that wraps the Prime → Machine pipeline for end-user consumption. Sibling repos: `prime` (orchestrator + compute), `manifold` (Rust math primitives), `orthon-engines` (compute engine registry), `machine` (ML layer).

## Workflow Discipline (cross-repo: prime, manifold, orthon-engines, machine, interface)

**Linear commits on `main`. No branches. No stashes.**

Single developer, no concurrent work to isolate. The workflow pattern is:

```
commit → change → commit → change → commit
```

**Rules — effective immediately, applies in every repo in the stack:**

1. **All commits land on `main`.** No `feature/`, `fix/`, `refactor/`, `chore/` branches. No long-lived working branches. The only branch is `main`.
2. **All test/benchmark runs execute against committed `main` only.** Never from a working tree with uncommitted changes, never from a detached HEAD, never from a branch that hasn't merged. If a benchmark needs to run, the change it's testing must be on `main` first.
3. **Tags anchor benchmark results to specific committed SHAs.** Vault entries reference tags. Reproducibility means `git checkout <tag> && run` — no clarification of "plus the working tree at the time" ever needed.
4. **Reverting goes backwards through `main` to a previous commit.** Linear navigation forward and backward only. No branch switches to "the old state". `git revert` (or `git reset --hard <previous-sha>` with explicit user authorization for destructive rewrites).
5. **Stashes are never used.** If working-tree changes exist when context-switching is needed, either commit them or discard them. No stashing across context switches, no stashing between sessions. `git stash` is forbidden.
6. **If a commit breaks something**, `git revert <sha>` and re-apply changes from there. Don't keep broken state in working tree as a "WIP" placeholder.
7. **Make changes small enough to revert trivially.** Uncertainty is a signal to shrink the change, not to delay the commit.

**Why this works for a single developer:** branches solve concurrent collaboration; without concurrency, branches add ceremony without value. Linear `main` makes provenance trivial — every benchmark result points at exactly one SHA, vault tags are unambiguous, and `git log main` IS the project history. No lost branches, no orphaned stashes, no "what was I doing yesterday?" — the linear log is the single source of truth.

## Cross-repo boundary

Interface CC NEVER modifies files outside `~/interface`. If a fix requires changes in `~/prime`, `~/manifold`, `~/orthon-engines`, or `~/machine`, document the change and surface it to the user — they will route the change to the correct repo's CC instance.
