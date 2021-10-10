# dotfiles
Stores configurations related to development environment.

## Prerequisites
- oh-my-zsh is expected to already be installed.

## Dot Setup
- Run `./update_links.sh` from within this directory. No it's not perfect, but it will link things.

## LunarVim
- Located in `~/.local/share/lunarvim/lvim
- Binary is in `~/.local/bin`
- Config goes in `~/.config/lvim`

### Setup
Make sure `~/.local/bin` is on the PATH. Then setup the config:
```
ln -s `pwd`/lvim ~/.config/lvim
```

Then run:
```
:TSInstall bash json lua python rust yaml javascript
:LspInstall bashls jsonls pyright rust_analyzer yamlls tsserver
:PackerInstall 
:PackerCompile
```

### Updating
Plugins:
```
:PackerUpdate
```

LunarVim:
```
cd ~/.local/share/lunarvim/lvim && git pull
:PackerSync
```
## Upgrade notes

Going from NVIM requires a full wipe of LVIM. You should delete:
- ~/.local/share/nvim/site/pack/packer 
- ~/.cache/nvim
- ~/.config/nvim

And re-install:
```
curl -LSs https://raw.githubusercontent.com/lunarvim/lunarvim/rolling/utils/installer/install.sh -O install.sh
LV_BRANCH=master bash ./install.sh
```
