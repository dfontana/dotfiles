# zx — pick and connect to a remote zmx session from the local terminal.
#
# The session list, history preview, and kill action are fetched over SSH, but
# fzf always runs locally. A private _zmx_host function may provide interactive
# host selection; otherwise ZMX_HOST supplies the SSH alias.
zx() {
  local host
  if typeset -f _zmx_host >/dev/null 2>&1; then
    host="$(_zmx_host)" || return 1
  elif [[ -n "${ZMX_HOST:-}" ]]; then
    host="$ZMX_HOST"
  else
    echo "zx: ZMX_HOST is not set and _zmx_host is not defined" >&2
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "zx: fzf not found on PATH" >&2
    return 1
  fi

  local sessions
  sessions=$(command ssh -T -- "$host" zmx ls --short) || return 1

  local output rc query selected session_name
  output=$(
    { [[ -n "$sessions" ]] && printf '%s\n' "$sessions"; } |
      ZX_PICK_HOST="$host" fzf \
        --print-query \
        --height=80% \
        --reverse \
        --prompt="zmx> " \
        --header="Enter: attach selected or create typed name | Shift+X: close" \
        --preview="printf '%s\n' {} | command ssh -T -- \"\$ZX_PICK_HOST\" 'IFS= read -r session; zmx history \"\$session\"' 2>/dev/null" \
        --preview-window=right:60%:follow \
        --bind="X:execute-silent(printf '%s\n' {} | command ssh -T -- \"\$ZX_PICK_HOST\" 'IFS= read -r session; zmx kill \"\$session\"')+reload(command ssh -T -- \"\$ZX_PICK_HOST\" zmx ls --short 2>/dev/null)"
  )
  rc=$?

  query=$(printf '%s\n' "$output" | sed -n '1p')
  selected=$(printf '%s\n' "$output" | sed -n '2p')

  if [[ $rc -eq 0 && -n "$selected" ]]; then
    session_name="$selected"
  elif [[ $rc -eq 1 && -n "$query" ]]; then
    session_name="$query"
  else
    return 130
  fi

  local escaped_session="${(qq)session_name}"
  command ssh -t -- "$host" "exec zmx attach ${escaped_session}"
}
