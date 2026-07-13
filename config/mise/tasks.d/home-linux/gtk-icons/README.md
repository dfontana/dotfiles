# gtk-icons

Rose Pine icon themes for home-linux, sourced from
[rose-pine/gtk](https://github.com/rose-pine/gtk).

`mise bootstrap` manages the whole lifecycle (see `mise.home-linux.toml`):

1. `[bootstrap.repos]` clones the repo into `rose-pine/` here (gitignored).
2. `[dotfiles]` links `rose-pine/icons/*-icons` into `~/.local/share/icons/`.
3. A post-dotfiles hook runs `gtk4-update-icon-cache` on each linked theme.

To pick up upstream changes, re-run `mise bootstrap` — the repos step updates
the checkout to the latest `main`.
