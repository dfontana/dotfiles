# zmx session management helpers — runs on both mac (no zmx) and remote (has zmx).
# See https://github.com/neurosnap/zmx#ssh-workflow for the ssh wiring.
if [[ -o interactive ]] && command -v zmx &>/dev/null; then
  eval "$(zmx completions zsh)"
fi

# zmx-attach [name] — the single entry point into a zmx session.
# Announces the session to the controlling kitty terminal (so smart_split.py and
# zls can read it via the zmx_session user var), then runs `zmx attach`.
# Every attach path (zp, zx, manual ssh) invokes this on the REMOTE side as:
#   zsh -c 'source ~/.config/zsh/zmx.zsh; zmx-attach <name>'
# The OSC must hit the raw ssh pty *before* `zmx attach` takes over — zmx drops
# OSC 1337 as unimplemented, so a hook inside the session never reaches kitty.
# Clear the marker when attach returns so conditional kitty key bindings never
# treat the resulting local shell as an active zmx client.
zmx-attach() {
  local session="${1:?zmx-attach: session name required}"
  local attach_status
  # kitty user var via OSC 1337 SetUserVar (value base64); kitty terminals only.
  if [[ "$TERM" == xterm-kitty* ]]; then
    printf '\033]1337;SetUserVar=zmx_session=%s\007' \
      "$(printf %s "$session" | base64 | tr -d '\n')"
  fi
  zmx attach "$session"
  attach_status=$?
  if [[ "$TERM" == xterm-kitty* ]]; then
    printf '\033]1337;SetUserVar=zmx_session\007'
  fi
  return "$attach_status"
}

# ---------------------------------------------------------------------------
# Remote session commands (meaningful only where zmx is installed)
# ---------------------------------------------------------------------------

# zmx-pick — interactively attach to an existing zmx session (Enter) or
# create one from the query (Ctrl-N). It deliberately lives in this shared
# zsh config rather than a deployed executable, so RemoteCommand can use it on
# every host that receives the dotfiles.
zmx-pick() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "zmx-pick: fzf not found on PATH" >&2
    return 1
  fi

  local display output rc query key selected session_name
  display=$(zmx list 2>/dev/null | while IFS=$'\t' read -r name pid clients created dir; do
    name=${name#*name=}
    pid=${pid#*pid=}
    clients=${clients#*clients=}
    dir=${dir#*start_dir=}
    printf "%-20s  pid:%-8s  clients:%-2s  %s\n" "$name" "$pid" "$clients" "$dir"
  done)

  output=$({ [[ -n "$display" ]] && printf '%s\n' "$display"; } | fzf \
    --print-query \
    --expect=ctrl-n \
    --height=80% \
    --reverse \
    --prompt="zmx> " \
    --header="Enter: attach | Ctrl-N: create new" \
    --preview='zmx history {1}' \
    --preview-window=right:60%:follow)
  rc=$?

  query=$(printf '%s\n' "$output" | sed -n '1p')
  key=$(printf '%s\n' "$output" | sed -n '2p')
  selected=$(printf '%s\n' "$output" | sed -n '3p')

  if [[ "$key" == ctrl-n ]]; then
    if [[ -z "$query" ]]; then
      echo "zmx-pick: enter a session name before pressing Ctrl-N" >&2
      return 1
    fi
    session_name=$query
  elif [[ $rc -eq 0 && -n "$selected" ]]; then
    session_name=${selected%%[[:space:]]*}
  elif [[ -n "$query" ]]; then
    session_name=$query
  else
    return 130
  fi

  zmx-attach "$session_name"
}

# zmx-split-from <origin-session> <new-session> — attach a new session that
# starts in the origin session's current working directory. The pid reported by
# `zmx list` is the session's shell process, so /proc/<pid>/cwd tracks its live
# cwd; fall back to the recorded start_dir (non-Linux hosts, dead pid), then
# $HOME. Used by smart_split.py via `zp --from` so remote splits keep the cwd.
zmx-split-from() {
  local origin="${1:?zmx-split-from: origin session required}"
  local session="${2:?zmx-split-from: new session name required}"
  local line pid start_dir dir
  line=$(zmx list 2>/dev/null | grep -F "name=${origin}"$'\t')
  pid=${line#*pid=}
  pid=${pid%%$'\t'*}
  start_dir=${line#*start_dir=}
  start_dir=${start_dir%%$'\t'*}
  dir=$(readlink "/proc/${pid}/cwd" 2>/dev/null)
  [[ -d "$dir" ]] || dir="$start_dir"
  [[ -d "$dir" ]] || dir="$HOME"
  cd "$dir" || cd "$HOME"
  zmx-attach "$session"
}

# zk — kill the current zmx session (requires $ZMX_SESSION to be set by zmx)
zk() {
  if [[ -z "${ZMX_SESSION:-}" ]]; then
    echo "zk: not inside a zmx session (ZMX_SESSION not set)" >&2
    return 1
  fi
  zmx kill "$ZMX_SESSION"
}

# zka — kill ALL active zmx sessions
zka() {
  local sessions
  sessions=$(zmx ls --short 2>/dev/null)
  if [[ -z "$sessions" ]]; then
    echo "zka: no active zmx sessions" >&2
    return 0
  fi
  printf '%s\n' "$sessions" | xargs zmx kill
}

# ---------------------------------------------------------------------------
# Local orchestration (Mac-side: open SSH panes into a remote zmx host)
# ---------------------------------------------------------------------------

# _zmx_host — resolve which SSH host to connect to.
# Default: reads $ZMX_HOST. Override this function in a private zsh file
# (e.g. werk.zsh) for dynamic host resolution (e.g. multi-workspace fzf pick).
# Guard: only define the default if not already defined by an earlier sourced file.
if ! typeset -f _zmx_host >/dev/null 2>&1; then
  _zmx_host() {
    if [[ -n "${ZMX_HOST:-}" ]]; then
      printf '%s\n' "$ZMX_HOST"
      return 0
    fi
    echo "_zmx_host: ZMX_HOST is not set." >&2
    echo "  Set it in a mise [env] block or define _zmx_host() in a private zsh config." >&2
    return 1
  }
fi

# zp [--from <session>] [name] — open a pane attached to a named zmx session on
# the remote host. If no name is given, auto-generates one (p<HHMMSS>). The
# session is created if it doesn't exist, or reattached if it does. When the
# SSH connection ends, the local shell remains open.
# --from <session> starts the new session in <session>'s current working
# directory (via zmx-split-from on the remote) — used by smart_split.py.
# Routes through zmx-attach (sourced on the remote) so the kitty window gets
# tagged with the session name — covers zp, zx and manual ssh uniformly.
zp() {
  [[ "${1:-}" == "--pick" ]] && {
    zx
    return
  }
  local host session origin remote_cmd
  if [[ "${1:-}" == "--from" ]]; then
    origin="${2:?zp: --from requires a session name}"
    shift 2
  fi
  host="$(_zmx_host)" || return 1
  session="${1:-p$(date +%H%M%S)}"
  if [[ -n "${origin:-}" ]]; then
    # (qqq) double-quotes the names — safe inside the single-quoted zsh -c below
    remote_cmd="zmx-split-from ${(qqq)origin} ${(qqq)session}"
  else
    remote_cmd="zmx-attach ${session}"
  fi
  command ssh -t \
    -o "RemoteCommand=zsh -c 'source ~/.config/zsh/zmx.zsh; ${remote_cmd}'" \
    "${host}"
}

# zx — open a pane with the remote fzf session picker. When the connection
# ends, the local shell remains open. Useful as a keybinding target without
# quoting: launch zsh -ic zx
zx() {
  local host
  host="$(_zmx_host)" || return 1
  command ssh -t \
    -o "RemoteCommand=zsh -c 'source ~/.config/zsh/zmx.zsh; zmx-pick'" \
    "${host}"
}

# zd — drop the SSH ControlMaster, detaching all zmx clients at once.
# Sessions keep running on the remote side.
zd() {
  local host
  host="$(_zmx_host)" || return 1
  echo "Dropping SSH master for ${host} (sessions persist remotely)..."
  command ssh -O exit "${host}" 2>&1 || true
  echo "Done. Reconnect with: zp [name]"
}
