# home-server — services (Disbot, RomM, yt-dlp updater)

Tracked service configuration for home-server, migrated from the private
`~/servers` repo. `~/servers` remains the runtime/data home (disbot binary,
romm library, secrets) — only version-tracked configuration lives here.
Game-specific servers (minecraft, valheim, v-rising, irc) intentionally stay
in the private repo.

Disbot is a native mise unit (`dev.mise.disbot-prod.service`), so it restarts
when `mise bootstrap` runs. The remaining server units are **static** — no
templating — to retain timer and Quadlet support. User-specific paths use the
systemd `%h` specifier (the data dir must be `~/servers`; symlink it there if it
ever moves), and container secrets load at runtime via
`EnvironmentFile=%h/servers/secrets.env` (schema in `secrets.example.env`,
never commit the real file, chmod 600).

## Layout

```
server-units.toml      task: validate secrets, daemon-reload, enable/start static units
server-init.toml       task: one-time firewall ports + user linger (sudo)
secrets.example.env    schema for ~/servers/secrets.env
systemd/user/          static user units (~/.config/systemd/user; yt-dlp timer)
systemd/containers/    Quadlet units (~/.config/containers/systemd)
romm/config.yml        romm app config, linked into ~/servers/romm/
```

## Usage (home-server only; tasks exist only with MISE_ENV=home-server)

Before the first real bootstrap, copy `secrets.example.env` to
`~/servers/secrets.env`, replace every `TBD`, keep `DB_USER`/`DB_PASSWD`
identical to `MARIADB_USER`/`MARIADB_PASSWORD`, and set mode 600. Then:

```sh
mise bootstrap --yes    # links config, then runs server-units on home-server
mise run server-units   # optional direct convergence after unit edits
mise run server-init    # one-time: firewall ports + user linger (sudo)
```

Mise dotfiles declaratively link the static user units, Quadlets, and RomM
config. `server-units` validates runtime secrets and is idempotent; it never
restarts a running static service. `mise bootstrap` restarts the native Disbot
unit. After editing a static unit, bootstrap or run it directly, then restart
the affected service (`systemctl --user restart <unit>`) yourself. Container env
changes (`secrets.env`) also require a restart to take effect.

Ports: 3450/tcp disbot admin UI, 3460/tcp romm.
