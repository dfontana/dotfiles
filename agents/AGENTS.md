# Global Agent Instructions

These instructions are tool-neutral and apply to every coding agent
(Claude Code, Pi, and future harnesses). Harness-specific behavior belongs in
that harness's adapter directory, not here.

## Version Control: Jujutsu

In a **jj** repo (`.jj/` at the root), run `jj diff -r @` before making edits to
confirm if the active revision is empty. If there are contents, make a new commit
only if you aren't contributing to the same commit as part of your task. Load the
`jujutsu` skill only for squashing, stacked PRs, conflicts, or unfamiliar
syntax — not at session start. Using `git` is blocked by a hook per harness.
