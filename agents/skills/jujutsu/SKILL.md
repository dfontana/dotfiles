---
name: jujutsu
description: >
  Jujutsu (jj) command reference for squashing, stacked pull requests,
  conflict resolution, and less common jj syntax. Load on demand when a jj
  operation goes beyond the basics. Do NOT load this at session start — the
  everyday rules (use jj not git, check @ is empty, describe intent first)
  are already in the global agent instructions.
---

# Jujutsu Reference

Reference material for jj operations beyond the everyday path. The basics —
never use raw `git`, check `@` is empty with `jj diff -r @`, declare intent
with `jj describe` before coding — live in the global agent instructions and
are not repeated here.

## Subagent Restrictions

Subagents may **inspect only**. Permitted commands:

- `jj log`, `jj status`, `jj diff`

Subagents must **never** run: `jj commit`, `jj describe`, `jj squash`,
`jj new`, or any other mutation. If a subagent detects it is on a non-empty
`@` and cannot safely proceed, it must defer to the parent agent to resolve
the situation.

## Commit Discipline

- Each revision must contain one logical chunk of work.
- `jj commit -m "..."` finalizes the current revision and opens a fresh empty `@`.
- If your harness requires a co-author trailer on commits, follow its rules;
  this skill imposes none.
- Related work across multiple revisions should be squashed before presenting
  to the user: `jj squash -r <rev> --into <target>`

## Command Reference

| Task | Command |
|------|---------|
| Check working copy status | `jj status` |
| Check if `@` is empty | `jj diff -r @` |
| View commit history | `jj log` |
| View a specific revision's diff | `jj diff -r <rev>` |
| Set description before coding | `jj describe -m "<intent>"` |
| Finalize revision, start fresh | `jj commit -m "<message>"` |
| Start a new empty revision explicitly | `jj new` |
| Squash revision into another | `jj squash -r <rev> --into <target>` |

## Key Differences from Git

- No staging area — all edits are automatically part of `@`
- `@` is always the working-copy revision
- `jj commit` = finalize `@` and create a new empty one (like `git commit -a` + fresh branch)
- `jj describe` = change the message of `@` without creating a new revision
- `jj new` = explicitly start a new empty revision without finalizing the current one

## Using gh CLI to create Pull Requests

`gh` works out of the box, however you must **ALWAYS** supply the `-H {bookmark}` argument 
to ensure the correct bookmark/branch is detected. Sometimes you may need to supply `-B {bookmark}`
to specify the base branch if stacking PRs. By default, the trunk branch is always used and is
correct when not stacking.
