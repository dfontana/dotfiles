# SilentSDDM on Fedora / Hyprland

SDDM is independent of Plasma. This setup uses its generic Wayland greeter
(Weston kiosk shell), not KWin or the Breeze login theme.

## Bootstrap

```sh
# Focused setup: fetch theme sources and run the final setup task.
mise bootstrap --only repos,task --skip-dirty
```

The currently installed mise version has a separate broad-dotfiles cleanup
regression: a full dry-run can propose pruning already-correct Kitty/Helix/Hunk/JJ
links. Until that is resolved, use the focused command above; the SDDM task
renders only its own staging file. `--skip-dirty` preserves the existing modified
Rose Pine icon checkout. No unrelated dotfile declarations/state were changed
as part of this setup.

The setup is also wired into the final task of a normal full `mise bootstrap`
for when that unrelated issue is resolved. The home-linux environment:
1. Fetches SilentSDDM v1.5.1 at release commit
   `d477613b07ca13729af20cb4699b308ac7348d2f` via `[bootstrap.repos]`.
   The ignored checkout lives beside these tasks in `SilentSDDM/`.
2. Renders the tracked SDDM template to the user-owned staging file
   `~/.config/sddm/zz-hyprland.conf`.
3. Runs its final `bootstrap` task, which depends on `sddm:setup`.

**The final bootstrap task uses sudo** and DNF may ask for confirmation. It
installs SDDM, Weston, fallback themes, and SilentSDDM's documented Fedora Qt6
SVG, virtual-keyboard, multimedia, and image-format dependencies. When present,
the Plasma greeter backend is swapped for the generic backend without automatic
dependency cleanup.

Only theme runtime assets are copied into `/usr/share/sddm/themes/silent`;
the upstream installer, scripts and Git metadata are not run or installed.
The upstream `configs/default.conf` preset is kept unchanged. Red Hat fonts
and their license are installed under `/usr/local/share/fonts/silent-sddm`.
Files become root-owned and readable by the greeter, SELinux contexts are
restored, and the font cache is refreshed.

The task applies `/etc/sddm.conf.d/zz-hyprland.conf` and enables SDDM.
It never starts/restarts SDDM, changes the default boot target, forcibly
replaces another display manager, edits PAM, enables autologin, or removes
Plasma. Hyprland and its repositories must already be installed/configured.
If another display manager owns `display-manager.service`, enabling SDDM fails
rather than replacing it forcibly.

## Reapply

After bootstrap has fetched the checkout, reapply just the SDDM setup:

```sh
mise run sddm:setup
```

Ordinary `mise dot apply` only stages configuration; it never invokes the
privileged setup. `sddm:configure` refreshes only its staged file with
`mise --no-hooks dot apply`, preventing unrelated hook execution.

## Configuration ownership and themes

The template is `config/mise/templates/sddm/zz-hyprland.conf`.
Its `sddm_theme` variable lives in `config/mise/mise.home-linux.toml`:
- `silent` (default): SilentSDDM, upstream default preset and keyboard environment.
- `elarun`: bundled recovery fallback, with no Silent-specific environment.

Run `mise run sddm:configure` after changing the variable. It validates the
installed theme's `Main.qml`, renders and checks the staged configuration, and
copies it as root-owned mode 0644 to `/etc`. Changed system configuration is
backed up beside it with a timestamped `.bak.*` suffix. It is deliberately not
a symlink from a privileged service into a user-writable repository.

`zz-` matters: SDDM reads drop-ins alphabetically, so `90-...` sorts **before**
an existing `kde_settings.conf`. Vendor drop-ins are read before local ones;
`/etc/sddm.conf` is read last and can override both. The task refuses to apply
if that primary file contains conflicting greeter settings.

To update SilentSDDM, review a new release, change the pinned `ref` in
`mise.home-linux.toml`, then bootstrap with `--update`. Local checkout edits
may block repository updates. Theme assets installed by these tasks are
managed copies; manual changes there can be overwritten. Further preset/color/
background customization should be added to this repository, not patched only
in the installed theme.

Manual configuration or the standalone `sddm-conf` GUI are alternatives;
Plasma's `sddm-kcm` is not needed. Prefer one configuration owner: GUI-written
`/etc/sddm.conf` may override mise's managed drop-in.

## Recovery

Keep a working TTY login available before changing the greeter. Do not restart
SDDM from an active graphical session: it terminates that session.
Preview first, save work, then test at a planned reboot.

If SilentSDDM fails, set `sddm_theme = "elarun"` in the machine config and run
`mise run sddm:configure` from the TTY. Alternatively restore the task's
timestamped configuration backup. Fallback themes are not uninstalled.
No authentication/PAM changes are involved.
