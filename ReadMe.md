# dotfiles
Stores configurations related to development environment.

## Prerequisites
- oh-my-zsh is expected to already be installed.
- Need these: 
  - All: fzf, rg, fnm, pynvim, starship, miniconda, bat, jenv, kubectx, dive, exa, temurin
  - Linux: xsel
  - Mac: cmake pkg-config
- Fonts: Install everything in `fonts/` folder

## Dot Setup
- Run `./install_neovim.sh` to get the latest neovim installed
- Run `./update_links.sh` from within this directory. No it's not perfect, but it will link things.

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


---

### (Deprecated)

#### Nvim 

Should bootstrap itself on launch but if you run into issues, check here

#### Treesitter reinstalls parsers on each launch 

Some cache is likely busted and re-installing plugins might help. But if that doesn't, just purge the following paths. It might be lazy's fault, it might not be, but since everything is managed in the dot files this is harmless to purge and reset...

```
~/.local/share/nvim/lazy/
~/.local/state/nvim/lazy/
```

#### LunarVim
- Located in `~/.local/share/lunarvim/lvim`
- Binary is in `~/.local/bin`
- Config goes in `~/.config/lvim`

#### Setup
Make sure `~/.local/bin` is on the PATH. Then run:
```
:LspInstall bashls jsonls pyright rust_analyzer yamlls tsserver
:PackerInstall 
:PackerCompile
```

#### Updating
Plugins:
```
:PackerSync
```

LunarVim:
```
:LvimUpdate
```
