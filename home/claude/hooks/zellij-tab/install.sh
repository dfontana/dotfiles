#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_DIR='$HOME/.claude/hooks/zellij-tab'
SETTINGS="$HOME/.claude/settings.json"

# Build and install the WASM plugin first.
"$SCRIPT_DIR/build.sh"

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

echo "zellij-tab hooks installed to $SETTINGS"
echo ""
echo "One manual step: add the plugin to load_plugins in config/zellij/config.kdl:"
echo ""
echo "  load_plugins {"
echo "      zellij:link"
echo "      file:~/.config/zellij/plugins/zellij-claude-tab.wasm"
echo "  }"
echo ""
echo "Then restart Zellij."
