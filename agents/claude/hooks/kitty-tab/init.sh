#!/usr/bin/env bash
# Shared slow-path logic for notification.sh and restore.sh.
# Sourced (not executed), so exit 0 on failure exits the caller intentionally.

CACHE_DIR="/tmp/claude-kitty-tab"
ORIG_FILE="$CACHE_DIR/${KITTY_WINDOW_ID}.original"
NOTIFY_FILE="$CACHE_DIR/${KITTY_WINDOW_ID}.notify"
# shellcheck disable=SC2034 # used by callers that source this file
STATE_FILE="$CACHE_DIR/${KITTY_WINDOW_ID}.state"

mkdir -p "$CACHE_DIR"
KITTY_OPTS=()
[[ -n "${KITTY_LISTEN_ON:-}" ]] && KITTY_OPTS=(--to "$KITTY_LISTEN_ON")
ALL_COLORS=$(kitty @ "${KITTY_OPTS[@]}" get-colors --match "id:$KITTY_WINDOW_ID" 2>/dev/null)
[[ -z "$ALL_COLORS" ]] && exit 0

active_bg=$(echo "$ALL_COLORS" | awk '/^active_tab_background/{print $2}')
inactive_bg=$(echo "$ALL_COLORS" | awk '/^inactive_tab_background/{print $2}')
mapfile -t ANSI_COLORS < <(echo "$ALL_COLORS" | awk 'NF==2 && $1~/^color([1-9]|1[0-4])$/{print $2}')
COLOR="${ANSI_COLORS[$((RANDOM % ${#ANSI_COLORS[@]}))]}"
[[ -z "$active_bg" || -z "$COLOR" ]] && exit 0

# Atomic writes to avoid races with concurrent hooks
printf '%s %s' "$active_bg" "$inactive_bg" >"${ORIG_FILE}.tmp" && mv "${ORIG_FILE}.tmp" "$ORIG_FILE"
printf '%s' "$COLOR" >"${NOTIFY_FILE}.tmp" && mv "${NOTIFY_FILE}.tmp" "$NOTIFY_FILE"
