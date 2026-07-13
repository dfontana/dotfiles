# kitty-specific helpers — layout save/restore for zmx sessions.
# These run on the local Mac where kitty is installed.
# Requires: allow_remote_control + listen_on in kitty.conf (already set).
# Keybinding targets: invoke via  launch [--type=background] zsh -ic zls
#                                  launch --location=hsplit  zsh -ic zlr

KITTY_LAYOUTS_DIR="${HOME}/dotfiles/config/kitty/layouts"

# zls [name] — save the focused kitty tab's zmx layout.
# If no name given, auto-names with a timestamp (auto-YYYYMMDD-HHMMSS).
# Each window's zmx session name is read from its "zmx_session" user variable,
# set at pane-open time by zp.
zls() {
  local label="${1:-auto-$(date +%Y%m%d-%H%M%S)}"
  mkdir -p "$KITTY_LAYOUTS_DIR"
  # KITTY_WINDOW_ID is this overlay/launcher window — exclude it so it
  # doesn’t appear as a pane in the saved layout.
  local self_id="${KITTY_WINDOW_ID:-}"
  kitten @ ls | jq --arg self_id "$self_id" '
    [.[] | .tabs[] | select(.is_focused)] | first |
    {
      tab_title: .title,
      layout:    .layout,
      windows: [
        .windows[] |
        select($self_id == "" or (.id | tostring) != $self_id) |
        {
          zmx_session: (.user_vars.zmx_session // ""),
          cwd:         .cwd,
          title:       .title,
          is_focused:  .is_focused
        }
      ]
    }
  ' > "${KITTY_LAYOUTS_DIR}/${label}.json"
  local count
  count=$(jq '.windows | length' "${KITTY_LAYOUTS_DIR}/${label}.json")
  echo "zls: saved '${label}' — ${count} pane(s) → ${KITTY_LAYOUTS_DIR}/${label}.json"
}

# zlr [name] — restore a saved zmx layout in a new kitty tab.
# If no name given, fzf-picks from saved layouts.
# First pane opens in a new tab; subsequent panes are horizontal splits.
# Each pane re-attaches to its saved zmx session via zp.
# Note: split ratios are not restored (v1 limitation); sessions are exact.
zlr() {
  local label
  if [[ -n "${1:-}" ]]; then
    label="$1"
  else
    label=$(
      ls "${KITTY_LAYOUTS_DIR}"/*.json 2>/dev/null \
        | xargs -I{} basename {} .json \
        | fzf --prompt="restore> " --height=10 --reverse
    )
  fi
  [[ -z "$label" ]] && return 0

  local layout_file="${KITTY_LAYOUTS_DIR}/${label}.json"
  [[ ! -f "$layout_file" ]] && { echo "zlr: layout '${label}' not found" >&2; return 1; }

  local count
  count=$(jq '.windows | length' "$layout_file")
  [[ "$count" -eq 0 ]] && { echo "zlr: no windows in layout" >&2; return 1; }

  # First window — new tab
  local first_session first_cwd
  first_session=$(jq -r '.windows[0].zmx_session // empty' "$layout_file")
  first_cwd=$(jq -r '.windows[0].cwd // empty' "$layout_file")
  local launch_args=(--type=tab "--tab-title=restored:${label}")
  [[ -n "$first_cwd" ]] && launch_args+=("--cwd=${first_cwd}")
  if [[ -n "$first_session" ]]; then
    kitten @ launch "${launch_args[@]}" zsh -ic "zp ${first_session}"
  else
    kitten @ launch "${launch_args[@]}"
  fi

  # Remaining windows — hsplit in the new tab
  for i in $(seq 1 $((count - 1))); do
    local session cwd
    session=$(jq -r ".windows[$i].zmx_session // empty" "$layout_file")
    cwd=$(jq -r ".windows[$i].cwd // empty" "$layout_file")
    local split_args=(--location=hsplit)
    [[ -n "$cwd" ]] && split_args+=("--cwd=${cwd}")
    if [[ -n "$session" ]]; then
      kitten @ launch "${split_args[@]}" zsh -ic "zp ${session}"
    else
      kitten @ launch "${split_args[@]}"
    fi
  done
  echo "zlr: restored '${label}' (${count} pane(s)) in new tab."
}
