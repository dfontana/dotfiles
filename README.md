# dotfiles
Stores configurations related to development environment.

## Prerequisites
- oh-my-zsh is expected to already be installed.
- Need these: 
  - All: dive, fd, fzf, fnm, jenv, git-delta, kubectx, miniconda, rg, starship, temurin
  - Linux: xsel
  - Mac: cmake pkg-config
- Fonts: Install everything in `fonts/` folder
  - On [Fedora](https://docs.fedoraproject.org/en-US/quick-docs/fonts/#user-fonts--command-line) this means making directory `~/.local/share/fonts/IosevkaCustom\ Nerd\ Font/` and copy all the `.ttf` files into. Then run `fc-cache -v` to update. Orrrrr pass the `LINK_FONTS=1` flag to `update_links.sh`

## Dot Setup
- Run `./update_links.sh` from within this directory. No it's not perfect, but it will link things.

## Font Rebuild
If you want to customize the fonts again in the future, use this [website](https://typeof.net/Iosevka/customizer) & import the `fonts/private-build-plans.toml`. This can be used to [run a custom build](https://github.com/be5invis/Iosevka/blob/main/doc/custom-build.md); which we'll use docker for. Utilize the script `fonts/docker-build` to do all the work.

Note: This will also patch the fonts with [nerd-fonts symbols](https://github.com/ryanoasis/nerd-fonts/wiki/ScriptOptions) for you.
Note: This also means the font family will now be "IosevkaCustom Nerd Font"

## Other tools
```
# Spotify TUI
cargo install spotify_player --no-default-features --features lyric-finder,image,daemon,rodio-backend,streaming,fzf

# Delta diffing tool hook into git
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3
```

---

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
