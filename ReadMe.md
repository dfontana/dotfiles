# dotfiles
Stores configurations related to development environment.

## Prerequisites
- oh-my-zsh is expected to already be installed.

## Using

- Run `./update_links.sh` from within this directory. No it's not perfect, but it will link things.
- Link nvim (not integrated into the above script yet) (Requires LunarVim installed)
```
ln -s `pwd`/nvim/lv-config.lua ~/.config/nvim/
ln -s `pwd`/nvim/vim-visual-multi.lua ~/.config/nvim/
```
