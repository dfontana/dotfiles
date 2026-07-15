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

[zmx](https://zmx.sh) replaces tmux/zellij for remote session persistence. The
only shell entry point is `zx`, defined in `config/zsh/zmx.zsh`. It resolves the
SSH host locally, downloads the remote session list, and runs `fzf` locally.
Selecting a session then connects with `ssh -t` and `zmx attach`.

The picker supports:

- `Enter`: attach to the selected session, or create and attach to a typed name when nothing is selected
- `Shift+X`: kill the selected remote session, reload the list, and keep picking

History previews are also fetched over SSH and rendered by the local picker.
There are no remote picker helpers, pane metadata, smart zmx splits, detach
commands, or layout save/restore helpers.

### SSH config

On `home` and `home-linux`, bootstrap manages the complete `~/.ssh/config`. It
includes untracked, machine-local `~/.ssh/config.private` first and then tracked
`~/.ssh/config.local`; the `home` template also includes Colima's
`~/.colima/ssh_config` when present. Put private or work-specific host blocks in
the former and shared personal host blocks in `home/ssh/config.local`.

Connection multiplexing remains useful for fast picker previews and reconnects:

```
Host kossserver.*
    ControlMaster auto
    ControlPath ~/.ssh/ctl-%C.socket
    ControlPersist 1s
    ForwardAgent yes
```

### Host resolution

`zx` uses an existing `_zmx_host()` function when a private zsh config defines
one, allowing local multi-host selection. Otherwise it uses the `ZMX_HOST`
environment variable declared by the machine's mise environment.

### Kitty keybindings

`cmd+shift+w` launches `zx` in a new local split, even when the focused pane is
connected to a remote session. The tab, pane, and resize modes remain unchanged
apart from all splits now being ordinary local splits.

