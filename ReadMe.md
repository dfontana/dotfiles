# dotfiles
Stores configurations related to development environment.

## Prerequisites
- oh-my-zsh is expected to already be installed.
- Need these: 
  - All: fzf, rg, fnm, starship, miniconda, bat, jenv, kubectx, dive, exa, temurin
  - Linux: xsel
  - Mac: cmake pkg-config
- Fonts: Install everything in `fonts/` folder

## Dot Setup
- Run `./update_links.sh` from within this directory. No it's not perfect, but it will link things.

### (Deprecated)

#### FanControl

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
