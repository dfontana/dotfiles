#!/usr/bin/env bash
set -euo pipefail

if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  echo "Error: bash 4+ is required (for mapfile). You have bash ${BASH_VERSION}." >&2
  echo "On macOS, install with: brew install bash" >&2
  exit 1
fi

HOOK_DIR='$HOME/.claude/hooks/kitty-tab'
SETTINGS="$HOME/.claude/settings.json"

if [[ ! -f "$SETTINGS" ]]; then
  printf '{}\n' >"$SETTINGS"
fi

jq \
  --arg ss "$HOOK_DIR/on-session-start.sh" \
  --arg not "$HOOK_DIR/notification.sh" \
  --arg rst "$HOOK_DIR/restore.sh" \
  --arg se "$HOOK_DIR/on-session-end.sh" \
  '
  def add_if_missing(event; cmd):
    if (.hooks[event] // [] | map(.hooks[]?.command) | any(. == cmd))
    then .
    else .hooks[event] += [{"hooks":[{"type":"command","command":cmd}]}]
    end;

  .hooks //= {} |
  add_if_missing("SessionStart";    $ss)  |
  add_if_missing("Stop";            $not) |
  add_if_missing("Notification";    $not) |
  add_if_missing("UserPromptSubmit";$rst) |
  add_if_missing("PreToolUse";      $rst) |
  add_if_missing("SessionEnd";      $rst) |
  add_if_missing("SessionEnd";      $se)
  ' "$SETTINGS" >"$SETTINGS.new" && mv "$SETTINGS.new" "$SETTINGS"

echo "kitty-tab hooks installed to $SETTINGS"
