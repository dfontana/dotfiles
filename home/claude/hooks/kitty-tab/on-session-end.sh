#!/bin/bash
[[ -z "$KITTY_WINDOW_ID" ]] && exit 0
cat >/dev/null  # discard stdin
kitty @ set-tab-title ""
