#!/usr/bin/env bash
[[ -z "$KITTY_WINDOW_ID" ]] && exit 0
cat >/dev/null # discard stdin

KITTY_OPTS=()
[[ -n "${KITTY_LISTEN_ON:-}" ]] && KITTY_OPTS=(--to "$KITTY_LISTEN_ON")
kitty @ "${KITTY_OPTS[@]}" set-tab-title --match "id:$KITTY_WINDOW_ID" "" >/dev/null 2>&1
