const fs = require('fs');
const path = require('path');
const os = require('os');

const CONFIG_FILE = 'notify.json';

const isTerminalFocused = async () => {
  if (process.platform === 'darwin') {
    try {
      const { execSync } = await import('child_process');
      const result = execSync('osascript -e \'tell application "System Events" to get name of first process whose frontmost is true\'', { encoding: 'utf-8' });
      const frontmost = result.trim().toLowerCase();
      const terminalApps = ['terminal', 'iterm', 'iterm2', 'alacritty', 'kitty', 'wezterm'];
      return terminalApps.some(app => frontmost.includes(app.toLowerCase()));
    } catch {
      return false;
    }
  } else if (process.platform === 'linux') {
    try {
      const { execSync } = await import('child_process');
      const result = execSync('xdotool getactivewindow getwindowname 2>/dev/null || echo ""', { encoding: 'utf-8' });
      return result.trim().length > 0;
    } catch {
      return false;
    }
  }
  return false;
};

const sendLocalNotification = async (message, title = 'OpenCode') => {
  const { execSync } = await import('child_process');
  if (process.platform === 'darwin') {
    try {
      execSync(`/usr/bin/osascript -e 'display notification "${message}" with title "${title}"'`, { 
        stdio: 'ignore',
        windowsHide: true 
      });
    } catch (e) {
      console.error('[notify] osascript error:', e.message, e.stderr);
    }
  }
};

const loadConfig = (configDir) => {
  const configPath = path.join(configDir, CONFIG_FILE);
  try {
    if (fs.existsSync(configPath)) {
      return JSON.parse(fs.readFileSync(configPath, 'utf-8'));
    }
  } catch (err) {
    console.error('[notify] Config error:', err.message);
  }
  return null;
};

export const Notify = async ({ directory }) => {
  const configDir = path.join(os.homedir(), '.config', 'opencode');
  const config = loadConfig(configDir);
  
  const settings = {
    suppressWhenFocused: config?.suppressWhenFocused ?? true,
    messages: {
      finished: config?.messages?.finished || 'opencode finished',
      needsAttention: config?.messages?.needsAttention || 'opencode needs attention'
    }
  };

  const handleNotification = async (event) => {
    let shouldNotify = false;
    let message;

    if (event.type === 'session.idle') {
      message = settings.messages.finished;
      shouldNotify = true;
    } else if (event.type === 'session.error' || 
               event.type === 'permission.asked' || 
               event.type === 'question.asked') {
      message = settings.messages.needsAttention;
      shouldNotify = true;
    }

    if (!shouldNotify || !message) return;

    if (settings.suppressWhenFocused) {
      const focused = await isTerminalFocused();
      if (focused) return;
    }

    sendLocalNotification(message).catch(err => {
      console.error('[notify] Notification error:', err.message);
    });
  };

  return {
    event: async (ctx) => {
      await handleNotification(ctx.event);
    }
  };
};
