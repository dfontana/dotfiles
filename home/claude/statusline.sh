#!/usr/bin/env bash
# ~/.claude/statusline.sh
# Claude Code status line — single line, compact, colorized, no emojis

# ---------- ANSI color helpers ----------
RESET='\033[0m'
BOLD='\033[1m'

FG_CYAN='\033[36m'
FG_YELLOW='\033[33m'
FG_GREEN='\033[32m'
FG_BLUE='\033[34m'
FG_MAGENTA='\033[35m'
FG_RED='\033[31m'
FG_GRAY='\033[90m'

SEP="${FG_GRAY}|${RESET}"

# ---------- Parse stdin ----------
if [ -t 0 ]; then
  input='{}'
else
  input=$(cat)
fi

model_name=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
cwd=$(echo "$input"        | jq -r '.cwd // .workspace.current_dir // ""')

cost_usd=$(echo "$input"     | jq -r '.cost.total_cost_usd // 0')
used_pct=$(echo "$input"     | jq -r '.context_window.used_percentage     // empty')

# ---------- 1. Model ----------
model_str="${BOLD}${FG_CYAN}${model_name}${RESET}"

# ---------- 2. Session cost ----------
cost_str="${FG_YELLOW}\$$(printf '%.4f' "$cost_usd")${RESET}"

# ---------- 3. Context progress bar + percentage ----------
bar_width=10
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  pct_int=$(printf "%.0f" "$used_pct")
  filled=$(( pct_int * bar_width / 100 ))
  empty=$(( bar_width - filled ))
  bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}#"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}-"; done

  # Color the bar: green <60%, yellow 60-85%, red >=85%
  if   [ "$pct_int" -ge 85 ]; then bar_color="$FG_RED"
  elif [ "$pct_int" -ge 60 ]; then bar_color="$FG_YELLOW"
  else                              bar_color="$FG_GREEN"
  fi
  ctx_str="${bar_color}[${bar}]${RESET} ${bar_color}${pct_int}%${RESET}"
else
  ctx_str="${FG_GRAY}[----------] --%${RESET}"
fi

# ---------- 4. CWD relative to ~ ----------
home_dir="$HOME"
if [[ "$cwd" == "$home_dir"* ]]; then
  rel_cwd="~${cwd#$home_dir}"
else
  rel_cwd="$cwd"
fi
cwd_str="${FG_BLUE}${rel_cwd}${RESET}"

# ---------- 5. VCS branch ----------
vcs_str=""

# Walk up from cwd to find .jj or .git
check_dir="$cwd"
found_jj=0
found_git=0
while [ -n "$check_dir" ] && [ "$check_dir" != "/" ]; do
  if [ -d "${check_dir}/.jj" ]; then
    found_jj=1
    break
  elif [ -d "${check_dir}/.git" ]; then
    found_git=1
    break
  fi
  check_dir="${check_dir%/*}"
done

if [ "$found_jj" -eq 1 ]; then
  # Show current bookmark; fall back to short change ID if no bookmark
  jj_branch=$(jj --no-pager log --no-graph -r @ \
    --template 'coalesce(bookmarks, "@" ++ change_id.short(8))' 2>/dev/null \
    | head -1 | xargs)
  if [ -n "$jj_branch" ]; then
    vcs_str="${FG_MAGENTA}jj:${jj_branch}${RESET}"
  else
    vcs_str="${FG_MAGENTA}jj:?${RESET}"
  fi
elif [ "$found_git" -eq 1 ]; then
  git_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -z "$git_branch" ]; then
    git_branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null || echo "?")
  fi
  vcs_str="${FG_GREEN}git:${git_branch}${RESET}"
else
  vcs_str="${FG_GRAY}[no vcs]${RESET}"
fi

# ---------- Assemble & print ----------
printf '%b\n' "${model_str} ${SEP} ${cost_str} ${SEP} ${ctx_str} ${SEP} ${cwd_str} ${SEP} ${vcs_str}"
