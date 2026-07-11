#!/usr/bin/env bash
[[ -z "$KITTY_WINDOW_ID" ]] && exit 0
cat >/dev/null # discard stdin

CACHE_DIR="/tmp/claude-kitty-tab"
ORIG_FILE="$CACHE_DIR/${KITTY_WINDOW_ID}.original"
NOTIFY_FILE="$CACHE_DIR/${KITTY_WINDOW_ID}.notify"
STATE_FILE="$CACHE_DIR/${KITTY_WINDOW_ID}.state"

KITTY_OPTS=()
[[ -n "${KITTY_LISTEN_ON:-}" ]] && KITTY_OPTS=(--to "$KITTY_LISTEN_ON")

if [[ -f "$ORIG_FILE" && -f "$NOTIFY_FILE" ]]; then
  [[ "$(cat "$STATE_FILE" 2>/dev/null)" == "original" ]] && exit 0
  read -r active_bg inactive_bg <"$ORIG_FILE"
  [[ -z "$active_bg" ]] && exit 0
  kitty @ "${KITTY_OPTS[@]}" set-tab-color --match "id:$KITTY_WINDOW_ID" active_bg="$active_bg" inactive_bg="$inactive_bg" >/dev/null 2>&1
  printf 'original' >"${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  exit 0
fi

# slow path: fetch colors once, populate all three cache files, restore original colors
# shellcheck source=init.sh
source "$(dirname "$0")/init.sh"
kitty @ "${KITTY_OPTS[@]}" set-tab-color --match "id:$KITTY_WINDOW_ID" active_bg="$active_bg" inactive_bg="$inactive_bg" >/dev/null 2>&1
printf 'original' >"${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
