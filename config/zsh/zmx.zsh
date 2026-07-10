# zmx session management helpers — runs on both mac (no zmx) and remote (has zmx).
# See https://github.com/neurosnap/zmx#ssh-workflow for the ssh wiring.
if [[ -o interactive ]] && command -v zmx &>/dev/null; then
  eval "$(zmx completions zsh)"
fi

# zmx-attach [name] — the single entry point into a zmx session.
# Announces the session to the controlling kitty terminal (so smart_split.py and
# zls can read it via the zmx_session user var), then hands off to `zmx attach`.
# Every attach path (zp, zpick, manual ssh) invokes this on the REMOTE side as:
#   zsh -c 'source ~/.config/zsh/zmx.zsh; zmx-attach <name>'
# The OSC must hit the raw ssh pty *before* `zmx attach` takes over — zmx drops
# OSC 1337 as unimplemented, so a hook inside the session never reaches kitty.
zmx-attach() {
  local session="${1:?zmx-attach: session name required}"
  # kitty user var via OSC 1337 SetUserVar (value base64); kitty terminals only.
  if [[ "$TERM" == xterm-kitty* ]]; then
    printf '\033]1337;SetUserVar=zmx_session=%s\007' \
      "$(printf %s "$session" | base64 | tr -d '\n')"
  fi
  exec zmx attach "$session"
}

# ---------------------------------------------------------------------------
# Remote session commands (meaningful only where zmx is installed)
# TODO: It feels like I could us a little cli-like wrapper on this with help & tab completions
#       easier to find them if I could do like `zx <tab>` and do subcommands that way
# ---------------------------------------------------------------------------

# zx — interactive session picker. zmx-pick is the standalone implementation;
#       alias here for short interactive use.
alias zx=zmx-pick

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

# zp [name] — open a pane attached to a named zmx session on the remote host.
# If no name is given, auto-generates one (p<HHMMSS>). The session is created
# if it doesn't exist, or reattached if it does.
# Routes through zmx-attach (sourced on the remote) so the kitty window gets
# tagged with the session name — covers zp, zpick and manual ssh uniformly.
zp() {
  [[ "${1:-}" == "--pick" ]] && { zpick; return; }
  local host session
  host="$(_zmx_host)" || return 1
  session="${1:-p$(date +%H%M%S)}"
  exec command ssh -t \
    -o "RemoteCommand=zsh -c 'source ~/.config/zsh/zmx.zsh; zmx-attach ${session}'" \
    "${host}"
}

# zpick — open a pane with the remote fzf session picker (zmx-pick).
# Useful as a keybinding target without quoting: launch zsh -ic zpick
zpick() {
  local host
  host="$(_zmx_host)" || return 1
  exec command ssh -t \
    -o "RemoteCommand=zmx-pick" \
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
