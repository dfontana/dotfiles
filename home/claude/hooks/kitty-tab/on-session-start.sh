#!/bin/bash
[[ -z "$KITTY_WINDOW_ID" ]] && exit 0
cat >/dev/null  # discard stdin

desc=""

# 1. jj named workspace (workspace root != repo root)
if jj_ws=$(jj workspace root --no-pager 2>/dev/null) &&
   jj_repo=$(jj root --no-pager 2>/dev/null) &&
   [[ "$jj_ws" != "$jj_repo" ]]; then
  desc=$(basename "$jj_ws")
fi

# 2. git linked worktree
if [[ -z "$desc" ]]; then
  if git_dir=$(git rev-parse --git-dir 2>/dev/null); then
    if [[ "$git_dir" == */.git/worktrees/* ]]; then
      toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
      desc=$(basename "$toplevel")
    fi
  fi
fi

# 3. Fallback: basename of cwd
[[ -z "$desc" ]] && desc=$(basename "$PWD")

kitty @ set-tab-title "Claude Code - $desc"
