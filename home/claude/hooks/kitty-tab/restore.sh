#!/bin/bash
kitty @ set-tab-color --match "id:$KITTY_WINDOW_ID" active_bg="$(kitty @ get-colors | grep '^active_tab_background' | awk '{print $2}')" inactive_bg="$(kitty @ get-colors | grep '^inactive_tab_background' | awk '{print $2}')"
