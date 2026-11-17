# What is this repo

dotfiles for all my machines.

Machines:
- home: this is my personal macbook
- home-linux: this is my personal fedora linux desktop
- home-server: this is my personal fedora linux server
- work / werk: these are work related dotfiles for my work latop and should not be checked into version control (hence they are git ignored)

Semantics:
- Any tool that can be managed by mise MUST be managed by mise
- Any function that can be a zsh function MUST be a function instead of a bin script, stored under config/zsh/ categorically
- bin scripts must be a last resort and used in well documented manners
- All setup must be idempotent or documented, making it reproducable and safe to setup multiple times

Setup:
- Linking and tool installation are done by `mise bootstrap`. Machine identity
  comes from MISE_ENV (~/.mise_env); config/mise/mise.<env>.toml adds that
  machine's declarations and hooks.
- On home-linux, bootstrap clones the Rose Pine icon repo (see
  config/mise/tasks.d/home-linux/gtk-icons/) and pinned SilentSDDM before
  linking, then refreshes font and GTK icon caches in post-dotfiles hooks.
  Its final `bootstrap` task runs `sddm:setup` with sudo to install the generic
  Wayland greeter, SilentSDDM assets/fonts, and root-owned configuration.
  This is explicitly opted in: never restart SDDM or edit PAM/autologin.
  Ordinary `mise dot apply` only stages SDDM configuration without sudo.
- On home-server, dotfiles link service configuration before bootstrap runs
  secret validation and selective enable/start automatically; privileged
  firewall/linger setup stays explicit.
- Machine-specific assets co-locate under config/mise/tasks.d/ (home-linux/,
  home-server/). update_links.sh and the general link tasks are deleted.

Coding agents:
- Shared config lives in agents/ (instructions, skills, Claude adapters, Pi
  read-only config, and settings defaults); declarative mise dotfiles link
  read-only files and bootstrap initializes writable Pi settings. OpenCode is
  removed.
- Pi credentials, trust decisions, sessions, caches, package install trees, and
  other mutable state remain machine-local. Never track or link `auth.json`.
- Project-level `.pi/` remains runtime/project state and is not globally linked.

# Formatting

if `shfmt` is available it must be ran: `shfmt -ci -i 2 -w {path to files touched}`
Only format files touched, never run across the entire repo (eg `.` is not acceptable)
