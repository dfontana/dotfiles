# dotfiles
Stores configurations related to development environment.

## Prerequisites
- oh-my-zsh is expected to already be installed.
- Need these: 
  - Mac: cmake pkg-config
  - Linux: Install kitty manually, dnf version is slow updates: https://sw.kovidgoyal.net/kitty/binary/
- Fonts: Install everything in `fonts/` folder
  - On [Fedora](https://docs.fedoraproject.org/en-US/quick-docs/fonts/#user-fonts--command-line) this means making directory `~/.local/share/fonts/IosevkaCustom\ Nerd\ Font/` and copy all the `.ttf` files into. Then run `fc-cache -v` to update. Orrrrr pass the `LINK_FONTS=1` flag to `update_links.sh`

## Dot Setup
- Run `./update_links.sh` from within this directory. No it's not perfect, but it will link things.

## Font Rebuild
If you want to customize the fonts again in the future, use this [website](https://typeof.net/Iosevka/customizer) & import the `fonts/private-build-plans.toml`. This can be used to [run a custom build](https://github.com/be5invis/Iosevka/blob/main/doc/custom-build.md); which we'll use docker for. Utilize the script `fonts/docker-build` to do all the work.

Note: This will also patch the fonts with [nerd-fonts symbols](https://github.com/ryanoasis/nerd-fonts/wiki/ScriptOptions) for you.
Note: This also means the font family will now be "IosevkaCustom Nerd Font Mono"
Note: There's a separate "Iosevka Nerd Font" / "icons" folder for the purpose of Waybar icons

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

---

## zmx — persistent remote terminal sessions

[zmx](https://zmx.sh) replaces tmux/zellij for remote session persistence. Sessions
live on the remote host; closing a terminal window detaches (session keeps running),
`exit`/Ctrl-D kills the session. Installed automatically via mise (`config.toml`).

### SSH config (manual step — not managed by dotfiles)

For each remote host, add a block to `~/.ssh/config.local` so SSH auto-attaches
to zmx and multiplexes panes over one connection:

```
Host kossserver.*
    RequestTTY yes
    ControlMaster auto
    ControlPath ~/.ssh/ctl-%C.socket
    ControlPersist 1s                  # master exits 1s after last channel closes
    ForwardAgent yes
```

`ControlPersist 1s` keeps sessions detached (not killed) when all panes close.
`ForwardAgent yes` lets the remote use your local SSH key for git etc.

### Host resolution — where `ZMX_HOST` comes from

`zp`/`zd`/`zpick` (defined in `config/zsh/zmx.zsh`) call `_zmx_host()` to find
the target SSH alias. Override `_zmx_host()` in a private zsh config to add
custom resolution logic (e.g. multi-host fzf picker in `werk.zsh`).

| Machine | Source |
|---|---|
| Home Mac | `config/mise/mise.home.toml` → `[env] ZMX_HOST = "homeserver"` |
| Work Mac | `werk.zsh` (gitignored) → `_zmx_host()` override |

### Kitty keybindings (`cmd+shift+w`)

| Key | Action |
|---|---|
| `>h` / `>v` | New hsplit / vsplit / tab — auto-named zmx session |
| `>r` | Resume: fzf picker (`zpick`) to reattach an existing session |
| `>d` | Detach all (drops SSH ControlMaster; sessions persist) |
| `>s` | Save current tab layout (background, auto-named timestamp) |
| `>o` | Restore a saved layout in a new tab (fzf-picks the layout) |

Saved layouts live in `config/kitty/layouts/` and can be committed.

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
