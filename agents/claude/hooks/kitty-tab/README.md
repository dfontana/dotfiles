# kitty-tab

Users of the kitty terminal can have their tabs colorized a random ansi color code (from 1-14) when claude needs their attention. This helps quickly spot which claude instance needs you, when working with many of them. Colors reset when claude is working away or you close the instance.

## Requirements

- [kitty](https://sw.kovidgoyal.net/kitty/) with remote control and a listen socket enabled in `kitty.conf`:
  ```
  allow_remote_control yes
  listen_on unix:/tmp/kitty-{kitty_pid}
  ```
- bash 4+ (macOS ships bash 3.2; install with `brew install bash`)
- `jq`

## Install

Run the install script (from any directory):

```sh
./install.sh
```

Requires `jq`. Safe to run multiple times.
