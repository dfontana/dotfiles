# Init Oh-my-zsh and path vars
export ZSH="~/.oh-my-zsh"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# Link the go version you want to use if its not the default in the repo currentl.
export PATH="/usr/lib/go-1.13/bin:$PATH"

# Creature comforts
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HYPHEN_INSENSITIVE="true"

# Init zsh plugins
fpath=(/usr/local/share/zsh-completions $fpath)
plugins=(z git ssh-agent docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)

# Theme to use, pick your fav
ZSH_THEME="spaceship"

# Fixes for plugins that dont want to work
source ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(kubectl completion zsh)
source $ZSH/oh-my-zsh.sh

# To help programs that read these
export VISUAL=vim
export EDITOR="$VISUAL"

# Launch tmux if it exists, we're interactive, and not already inside a tmux
alias tmux=tmux new-session -A -s main
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux new-session -A -s main
fi
