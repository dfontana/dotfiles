#!/usr/bin/env bash
[[ -z "${ZELLIJ_PANE_ID:-}" ]] && exit 0
cat >/dev/null # discard stdin

zellij pipe \
  --name "claude-tab" \
  --payload "notify:${ZELLIJ_PANE_ID}" \
  >/dev/null 2>&1 || true
