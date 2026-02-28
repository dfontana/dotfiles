# Global Agent Instructions

## Version Control: Jujutsu

If a `.jj/` directory exists at the repository root, this project uses
**Jujutsu (jj)** for version control. Load the `jujutsu` skill immediately
and follow its workflow rules for all VCS operations.

## Code Review

Before making any commit, spawn the `code-reviewer` agent and complete its
checklist. Do not commit until all checks pass.
