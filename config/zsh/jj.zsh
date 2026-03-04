alias jj="nocorrect jj" # Stop telling me I'm wrong you jerk

# gh doesn't work in jj workspaces, this fixes it. If you aren't in a jj workspace
# we just pass through to the actual
gh() {
  local root repo git_target git_dir head_branch
  if root=$(jj root 2>/dev/null) && [[ -f "$root/.jj/repo" ]]; then
    repo=$(cat "$root/.jj/repo")
    git_target=$(cat "$repo/store/git_target")
    git_dir=$(realpath "$repo/store/$git_target")

    # Parse -H/--head to create local branch ref if it only exists on remote
    local args=("$@")
    for ((i = 1; i <= ${#args}; i++)); do
      if [[ "${args[$i]}" == "-H" || "${args[$i]}" == "--head" ]]; then
        head_branch="${args[$((i + 1))]}"
        break
      fi
    done
    if [[ -n "$head_branch" ]]; then
      GIT_DIR="$git_dir" git show-ref --verify --quiet "refs/heads/$head_branch" 2>/dev/null ||
        GIT_DIR="$git_dir" git branch "$head_branch" "origin/$head_branch" 2>/dev/null || true
    fi

    GIT_DIR="$git_dir" command gh "$@"
  else
    command gh "$@"
  fi
}

# What files have been touched (when workng with jj)?
jjtouch() {
  if [[ $# -gt 1 ]]; then
    jj diff --types -r "$1" | grep "$2" | awk 'substr($1, 2, 1) != "-" {printf "%s ", $2}'
  elif [[ $# -eq 1 ]]; then
    jj diff --types -r @- | grep "$1" | awk 'substr($1, 2, 1) != "-" {printf "%s ", $2}'
  else
    jj diff --types -r @- | awk 'substr($1, 2, 1) != "-" {printf "%s ", $2}'
  fi
}

# Interactive jj log viewer powered by fzf.
# Default view: ancestors of @. Toggle modes with keybindings.
# ctrl-a: all revisions  ctrl-d: stack (trunk..@)  ctrl-b: bookmark heads
# enter: jj new on rev    ctrl-e: jj edit rev
jjl() {
  local tmpl='change_id.short(8) ++ " " ++ separate(" ", local_bookmarks.map(|b| "[" ++ b.name() ++ "]").join(""), description.first_line()) ++ "\n"'
  jj log -r 'bookmarks()' --no-graph -T "$tmpl" --color=always |
    fzf \
      --ansi \
      --no-sort \
      --layout=reverse \
      --prompt="bookmarks> " \
      --header=$'ctrl-a: all | ctrl-d: stack | ctrl-b: bookmarks | esc: reset\nenter: new on rev | ctrl-e: edit rev' \
      --preview "jj log -r 'trunk()::{1}' --color=always" \
      --bind 'start,resize:transform:[[ $FZF_COLUMNS -lt 120 ]] && echo "change-preview-window(up,40%,wrap)" || echo "change-preview-window(right,60%,wrap)"' \
      --bind "ctrl-a:reload[jj log --no-graph -T '$tmpl' --color=always]+change-prompt[all> ]" \
      --bind "ctrl-d:reload[jj log -r 'trunk()::{1}' --no-graph -T '$tmpl' --color=always]+change-prompt[stack> ]" \
      --bind "ctrl-b:reload[jj log -r 'bookmarks()' --no-graph -T '$tmpl' --color=always]+change-prompt[bookmarks> ]" \
      --bind "esc:reload[jj log -r 'bookmarks()' --no-graph -T '$tmpl' --color=always]+change-prompt[bookmarks> ]" \
      --bind "ctrl-e:execute(jj edit {1})" \
      --bind "enter:become(jj new {1})"
}

# Interactive jj workspace manager powered by fzf.
# enter: cd into workspace  ctrl-x: jj forget + rm -rf  ctrl-n: create new workspace
_jjw_new() {
  local name
  printf "Workspace name: " >&2
  read -r name
  [[ -z "$name" ]] && return 1

  local ws_path="$HOME/workspaces/$name"
  local tmpl='change_id.short(8) ++ " " ++ separate(" ", local_bookmarks.map(|b| "[" ++ b.name() ++ "]").join(""), description.first_line()) ++ "\n"'

  local rev
  rev=$(
    jj log --no-graph -T "$tmpl" --color=always |
      fzf --ansi --no-sort --layout=reverse \
        --prompt="revision for '$name'> " \
        --header="Select parent revision (esc to cancel)" \
        --preview "jj show {1} --color=always" \
        --bind 'start,resize:transform:[[ $FZF_COLUMNS -lt 120 ]] && echo "change-preview-window(up,40%,wrap)" || echo "change-preview-window(right,60%,wrap)"' |
      awk '{print $1}'
  )
  [[ -z "$rev" ]] && return 1

  mkdir -p "$HOME/workspaces"
  jj workspace add "$ws_path" -r "$rev" || return 1

  # Per-repo init hook: <repo_root>/.jj-workspace-init called with workspace path as $1
  local init
  init="$(jj root 2>/dev/null)/.jj-workspace-init"
  [[ -x "$init" ]] && "$init" "$ws_path"

  echo "$ws_path"
}

jjw() {
  local tmpl='self.name() ++ "  " ++ self.target().description().first_line() ++ "\n"'

  local result
  result=$(
    jj workspace list -T "$tmpl" |
      fzf \
        --ansi \
        --no-sort \
        --layout=reverse \
        --prompt="workspaces> " \
        --header=$'enter: cd | ctrl-x: delete (forget + rm) | ctrl-n: new' \
        --preview "jj log -r 'trunk()::{1}@' -s --color=always" \
        --bind 'start,resize:transform:[[ $FZF_COLUMNS -lt 120 ]] && echo "change-preview-window(up,40%,wrap)" || echo "change-preview-window(right,60%,wrap)"' \
        --bind "ctrl-x:execute[p=\$(jj workspace root --name {1}) && jj workspace forget {1} && rm -rf \$p]+reload[jj workspace list -T '$tmpl']" \
        --bind "ctrl-n:become(echo __new__)" \
        --bind "enter:become(echo \$(jj workspace root --name {1}))"
  )

  case "$result" in
    __new__)
      local new_path
      new_path=$(_jjw_new)
      [[ -n "$new_path" ]] && cd "$new_path"
      ;;
    "") ;;
    *) cd "$result" ;;
  esac
}
