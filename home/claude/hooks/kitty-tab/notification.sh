#!/bin/bash
ANSI_COLORS=($(kitty @ get-colors | grep -E '^color[0-9]+ ' | awk '{print $2}'))
COLOR="${ANSI_COLORS[$((RANDOM % 14 + 1))]}"
kitty @ set-tab-color --match "id:$KITTY_WINDOW_ID" active_bg="$COLOR" inactive_bg="$COLOR"
