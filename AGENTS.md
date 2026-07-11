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
- Linking and tool installation are done by `mise bootstrap` (see
  mise-migrate-dots.md). Machine identity comes from MISE_ENV (~/.mise_env);
  config/mise/mise.<env>.toml adds that machine's declarations and hooks.
- On home-linux, bootstrap initializes the GTK submodule before linking, then
  refreshes the tracked font and GTK icon caches.
- On home-server, bootstrap validates secrets and runs the selective systemd
  link/enable/start task automatically; privileged firewall/linger setup stays
  explicit.
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
