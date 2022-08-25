# dotfiles
Stores configurations related to development environment.

## Prerequisites
- oh-my-zsh is expected to already be installed.
- fzf, rg, fnm, pynvim
- Linux: xsel
- Fonts:
  - Caskadiya Code (Mono!)
  - Nerd Fonts Symbols Only (Mono!)

## Dot Setup
- Run `./install_neovim.sh` to get the latest neovim installed
- Run `./update_links.sh` from within this directory. No it's not perfect, but it will link things.


## LunarVim
- Located in `~/.local/share/lunarvim/lvim`
- Binary is in `~/.local/bin`
- Config goes in `~/.config/lvim`

### Setup
Make sure `~/.local/bin` is on the PATH. Then run:
```
:LspInstall bashls jsonls pyright rust_analyzer yamlls tsserver
:PackerInstall 
:PackerCompile
```

### Updating
Plugins:
```
:PackerSync
```

LunarVim:
```
:LvimUpdate
```

## FanControl

For linux fan profile management.

- Init the submodule (or update it):
```
Init module:    git submodule update --init --recursive
Update module:  git submodule update --remote --merge
```

- Install python deps:
```
pip install ./fancontrol/liquidctl psutil
sudo pip install psutil
```

