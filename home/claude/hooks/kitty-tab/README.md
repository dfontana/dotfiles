# kitty-tab

Users of the kitty terminal can have their tabs colorized a random ansi color code (from 1-14) when claude needs their attention. This helps quickly spot which claude instance needs you, when working with many of them. Colors reset when claude is working away or you close the instance.

Add these hooks to your `settings.json`:
```json
"hooks": {
    "Stop": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/kitty-tab/notification.sh" }] }],
    "Notification": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/kitty-tab/notification.sh" }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/kitty-tab/restore.sh" }] }],
    "PreToolUse": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/kitty-tab/restore.sh" }] }],
    "SessionEnd": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/kitty-tab/restore.sh" }, { "type": "command", "command": "$HOME/.claude/hooks/kitty-tab/on-session-end.sh" }] }]
  }
```
