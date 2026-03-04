alias jj="nocorrect jj" # Stop telling me I'm wrong you jerk

# What files have been touched (when workng with jj)?
jjtouch(){
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
# ctrl-a: all revisions  ctrl-d: ancestors of @  ctrl-b: bookmark heads
# ctrl-m: mutable heads  enter: full jj show     ctrl-e: jj edit rev
jjl() {
  local tmpl='change_id.short(8) ++ " " ++ separate(" ", local_bookmarks.map(|b| "[" ++ b.name() ++ "]").join(""), description.first_line()) ++ "\n"'
  jj log -r "ancestors(@, 40)" --no-graph -T "$tmpl" --color=always |
    fzf \
      --ansi \
      --no-sort \
      --layout=reverse \
      --prompt="ancestors(@)> " \
      --header=$'ctrl-a: all | ctrl-d: ancestors | ctrl-b: bookmarks | ctrl-m: mutable heads\nenter: show diff | ctrl-e: edit rev' \
      --preview "jj show {1} --color=always" \
      --bind 'start,resize:transform:[[ $FZF_COLUMNS -lt 120 ]] && echo "change-preview-window(up,40%,wrap)" || echo "change-preview-window(right,60%,wrap)"' \
      --bind "ctrl-a:reload[jj log --no-graph -T '$tmpl' --color=always]+change-prompt[all> ]" \
      --bind "ctrl-d:reload[jj log -r 'ancestors(@, 40)' --no-graph -T '$tmpl' --color=always]+change-prompt[ancestors(@)> ]" \
      --bind "ctrl-b:reload[jj log -r 'bookmarks()' --no-graph -T '$tmpl' --color=always]+change-prompt[bookmarks> ]" \
      --bind "ctrl-m:reload[jj log -r 'heads(mutable())' --no-graph -T '$tmpl' --color=always]+change-prompt[mutable heads> ]" \
      --bind "ctrl-e:execute(jj edit {1})" \
      --bind "enter:become(jj show {1} --color=always | less -R)"
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
    jj log -r "ancestors(@, 40)" --no-graph -T "$tmpl" --color=always |
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
  local tmpl='name ++ "  " ++ working_copy.description().first_line() ++ "\t" ++ path ++ "\n"'

  local result
  result=$(
    jj workspace list -T "$tmpl" |
      fzf \
        --ansi \
        --no-sort \
        --delimiter=$'\t' \
        --with-nth=1 \
        --prompt="workspaces> " \
        --header=$'enter: cd | ctrl-x: delete (forget + rm) | ctrl-n: new' \
        --preview "jj -R {2} log --color=always" \
        --bind 'start,resize:transform:[[ $FZF_COLUMNS -lt 120 ]] && echo "change-preview-window(up,40%,wrap)" || echo "change-preview-window(right,60%,wrap)"' \
        --bind "ctrl-x:execute[jj workspace forget {1} && rm -rf {2}]+reload[jj workspace list -T '$tmpl']" \
        --bind "ctrl-n:become(echo __new__)" \
        --bind "enter:become(echo {2})"
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
