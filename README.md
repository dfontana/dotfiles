# dotfiles
Stores configurations related to development environment.

## Prerequisites
- Install Git, [mise](https://mise.jdx.dev/getting-started.html), and
  [oh-my-zsh](https://ohmyz.sh/) with the `zsh-autosuggestions` and
  `zsh-syntax-highlighting` plugins.
- On Linux, install [Kitty](https://sw.kovidgoyal.net/kitty/binary/) directly.
  `home-linux` also requires `fc-cache` and `gtk4-update-icon-cache`.

## Dot Setup
Clone this repo and choose its machine environment:

```sh
git clone <this repo> && cd dotfiles
mkdir -p ~/.config
ln -ns "$PWD/config/mise" ~/.config/mise
printf "export MISE_ENV='%s'\n" '<machine>' >~/.mise_env
export MISE_ENV='<machine>' # home | home-linux | home-server | work
mise bootstrap --yes
```

`MISE_ENV` is `home` (macOS), `home-linux` (Fedora desktop), `home-server`
(Fedora server), or `work` (work laptop). It is loaded from `~/.mise_env` in
new shells.

### Migrating from direct linking

Before bootstrapping an existing machine, replace any whole-directory symlink
that now contains separately managed templates with a real directory. Otherwise
mise may render into the repository or create self-referential links:

```sh
# Repeat for each affected directory (for example: helix or kitty).
name=helix
unlink "$HOME/.config/$name" # removes only the symlink, not its repository target
mkdir -p "$HOME/.config/$name"

# Run after migrating every affected directory.
mise bootstrap --yes
```

For `home-server`, ensure the private `~/servers` runtime is in place. Before
the first bootstrap, create `~/servers/secrets.env` from
`config/mise/tasks.d/home-server/secrets.example.env`, fill in its values, and
run `chmod 600 ~/servers/secrets.env`. Run `mise run server-init` once after
bootstrap to configure the firewall and user linger.

## Font Rebuild
If you want to customize the fonts again in the future, use this [website](https://typeof.net/Iosevka/customizer) & import the `config/mise/tasks.d/home-linux/fonts/private-build-plans.toml`. This can be used to [run a custom build](https://github.com/be5invis/Iosevka/blob/main/doc/custom-build.md); which we'll use docker for. Run `mise run fonts:rebuild` to do all the work (see `mise tasks ls` for the individual `fonts:*` steps).

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

### SSH config

On `home` and `home-linux`, bootstrap manages the complete
`~/.ssh/config`. It includes untracked, machine-local `~/.ssh/config.private`
first and then tracked `~/.ssh/config.local`; the `home` template also includes
Colima's `~/.colima/ssh_config` when present. Put private or work-specific host
blocks in the former;
add shared personal host blocks to `home/ssh/config.local` so SSH auto-attaches
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

