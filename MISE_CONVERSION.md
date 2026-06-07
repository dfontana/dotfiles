# Cleanup on new system
- Remove nvm and any installed versions of node through it
- Remove fnm and any installed versions of node through it
- Remove bun and any installed global deps (bun pm -g ls)
- Remove conda and any installed deps through it (may be miniforge, follow readme)
- `cargo install --list` -> Remove those items (for mise)
- If installed through homebrew, remove rustup/cargo/rust. You should uninstall rust versions managed through rustup to let mise work (rustup toolchain list)

## Left todo

- Figure out a better way to handle the autocomplete and syntax highlighting plugins, since they are messy atm
- Set `MISE_ENV` in zshrc:
 - `home`: macbook
 - `work,workbox`: work devbox

# uninstall list (work-devbox)
- `.cargo/env` workaround (don't need it anymore at all, no rust needed there)
