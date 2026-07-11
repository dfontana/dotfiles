# Global Agent Instructions

These instructions are tool-neutral and apply to every coding agent
(Claude Code, Pi, and future harnesses). Harness-specific behavior belongs in
that harness's adapter directory, not here.

## Version Control: Jujutsu

If a `.jj/` directory exists at the repository root, the project uses
**Jujutsu (jj)** for version control. Load the `jujutsu` skill immediately
and follow its workflow rules for all VCS operations.
