# Cleanup on new system
- Remove nvm and any installed versions of node through it
- Remove fnm and any installed versions of node through it
- Remove bun and any installed global deps (bun pm -g ls)
- Remove conda and any installed deps through it (may be miniforge, follow readme)
- `cargo install --list` -> Remove those items (for mise)
- If installed through homebrew, remove rustup/cargo/rust. You should uninstall rust versions managed through rustup to let mise work.

## Left todo

- Figure out a better way to handle the autocomplete and syntax highlighting plugins, since they are messy atm
- `arrus` has a systemd unit in your dotfiles, looking for the cargo path. Can mise be used in systemd units?
- Set `MISE_ENV` in zshrc:
 - `home`: macbook
 - `work`: work macbook
 - `work,workbox`: work devbox
- Work laptop:
  - jenv is replaced with mise (make sure it works first though). https://mac.install.guide/mise/mise-java-mac
  - fnm is replaced with mise (uninstall it)
  - remove ssh config block once included && delete the werk.zsh ssh lines

# uninstall list (work)
- brew uninstal apacke-flink bat colima crane dive duckdb erdtree fd fnm fzf gh git-delta glow helm jenv jj jq kubectl kubectx openjdk@17 openjdk@21 ripgrep ruff sbt shellcheck shfmt starship yq zellij

# uninstall list (work-devbox)
- `.cargo/env` workaround (don't need it anymore at all, no rust needed there)
