export const NoGitPlugin = async ({ project, directory }) => {
  const isGitCommand = (cmd) => {
    const gitCommands = [
      'git',
      'git-add',
      'git-branch',
      'git-checkout',
      'git-commit',
      'git-diff',
      'git-fetch',
      'git-init',
      'git-log',
      'git-merge',
      'git-pull',
      'git-push',
      'git-rebase',
      'git-reset',
      'git-status',
    ];
    return gitCommands.some(gitCmd => cmd.startsWith(gitCmd));
  };

  return {
    event: async ({ event }) => {
      if (event.type === 'tool.execute.before') {
        const { tool, args } = event.data;

        if (tool === 'bash') {
          const command = args.command || '';

          const hasJjDir = await checkForJj(directory);

          if (hasJjDir && isGitCommand(command)) {
            throw new Error(
              `🚫 Git command blocked: This project uses Jujutsu (jj).\n\n` +
              `The command "${command}" is not allowed because a .jj/ directory exists.\n\n` +
              `Please use jj instead. For example:\n` +
              `  • git status    → jj log` +
              `  • git add      → jj commit` +
              `  • git commit   → jj commit` +
              `  • git push     → jj push` +
              `  • git pull     → jj pull` +
              `  • git diff     → jj diff` +
              `  • git branch   → jj branch` +
              `  • git log      → jj log`
            );
          }
        }
      }
    }
  };
};

async function checkForJj(dir) {
  try {
    const fs = await import('fs');
    return fs.existsSync(`${dir}/.jj`);
  } catch {
    return false;
  }
}
