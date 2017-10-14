# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# Set name of the zsh theme and dir colors to load. Look in ~/.oh-my-zsh/themes/
ZSH_THEME="mySoliah"

ENABLE_CORRECTION="true"                            #Command auto-correction.
COMPLETION_WAITING_DOTS="true"                      #Display red dots whilst waiting

fpath=(/usr/local/share/zsh-completions $fpath)
plugins=(z git ssh-agent zsh-syntax-highlighting)             # Load plugins

zstyle :omz:plugins:ssh-agent identities id_rsa
zstyle :omz:plugins:ssh-agent lifetime 4h

# Login to SSH_Agents
#if [ ! -S ~/.ssh/ssh_auth_sock ]; then
#	eval `ssh-agent`
#fi
#ssh-add -l | grep "The agent has no identities" && ssh-add

# Enable syntax highlighting, enable promptline.vim powerline symbols (see plugin page) && launch.
source ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.shell_prompt.sh
source $ZSH/oh-my-zsh.sh

# Preview MD files in terminal by using lynx, pandoc
rmd () {
    pandoc $1 | lynx -stdin
}
