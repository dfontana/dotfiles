# Zmx pane management redesign

## Status

Planned. This document describes a narrower, local-first model for zmx-managed Kitty panes. It intentionally does **not** implement remote working-directory cloning; that is a separate capability with no reliable zmx API today.

## Goals

- Make `zp`-opened panes reliable managed connections.
- Keep the managed-pane lifecycle entirely on the local machine, where Kitty and the SSH client are observable.
- Persist both the SSH host and zmx session so `zls`/`zlr` can restore multi-host layouts without a host picker.
- Make `zx` select sessions locally and then use the same `zp` lifecycle as every other managed connection.
- Treat direct `zmx attach` usage as intentionally unmanaged rather than trying to infer remote process state.
- Remove `zmx-attach`, `zmx-pick`, and the detach-only marker behavior.

## Non-goals

- Detect `ZMX_SESSION` from arbitrary SSH panes.
- Make direct `zmx attach` panes participate in smart zmx splits or layout persistence.
- Recreate a new zmx session in the focused session's *current* remote directory.
- Add a generic remote process watcher or poll zmx socket/log state.

## Why this redesign is needed

The existing design has the remote `zmx-attach` helper set and clear Kitty's `zmx_session` user variable over OSC 1337:

```text
remote zmx-attach → set Kitty user variable → zmx attach → clear user variable
```

This makes remote process exit responsible for local terminal state. If the remote attach command does not reach its cleanup code, Kitty retains `zmx_session` even after the local pane has returned to a normal shell. `smart_split.py` then treats a non-zmx pane as zmx-managed and runs `zp`.

The same metadata is incomplete for layouts. It contains only a zmx session name, not the host on which the session lives. When `_zmx_host` presents a host picker, `zlr` cannot deterministically reconnect a saved session.

Finally, `ZMX_SESSION` cannot replace Kitty user variables:

```text
Kitty → local zsh → local ssh ─────────── SSH stream ─────────── remote zmx → remote shell
                                                                ZMX_SESSION lives here
```

Kitty can inspect the local child process and its initial environment, but not the remote zmx session environment. Remote zmx session discovery also cannot identify which of several SSH terminal streams is attached to which session. Managed panes therefore need explicit metadata; Kitty user variables remain the appropriate local storage for it.

## Design principles

1. **`zp` owns managed-pane state locally.** It has the Kitty window, selected SSH alias, generated or supplied session name, and the local `ssh` process whose exit ends the connection.
2. **Managed metadata is a connection descriptor.** It contains both `host` and `session`, never just a session name.
3. **One local path manages every managed connection.** `zp`, `zx`, smart splitting, and layout restore all converge on `zp --host … --session …`.
4. **Direct zmx is valid but unmanaged.** `ssh host; zmx attach name` must continue to work, but it does not opt into Kitty-managed connection behavior.
5. **Do not infer remote state from terminal process heuristics.** A stale-metadata safeguard may inspect the local SSH process, but it is not the source of truth.

## Proposed local metadata

Use separate Kitty user variables on the local window:

```text
zmx_host=<SSH alias>
zmx_session=<zmx session name>
```

A pane is managed only when **both** values are nonempty. Keeping the values separate makes them directly available to Kitty kittens and to `kitten @ ls`; it avoids encoding and parsing a custom compound string.

`zmx_host` must be the SSH alias actually selected by the local machine, rather than a remote hostname. That preserves per-machine SSH configuration such as `ProxyJump`, user overrides, agent settings, and custom transport configuration.

## `zp`: local lifecycle owner

### Interface

Replace the current positional-only interface with an explicit connection form:

```text
zp [--host <ssh-alias>] [--session <zmx-session>]
```

Behavior:

- Without `--host`, resolve a host through `_zmx_host` as today.
- Without `--session`, generate the existing `p<HHMMSS>` style session name.
- With both options, do no interactive selection.
- Keep a convenient positional session form only if it does not make host/session parsing ambiguous.

### Lifecycle

Before opening SSH, `zp` sets both variables on **its own local Kitty window** using Kitty remote control, for example through `kitten @ set-user-vars` targeted at `$KITTY_WINDOW_ID`.

It then runs the normal SSH client and direct zmx command:

```text
local zp
  ├── set zmx_host + zmx_session on this Kitty window
  ├── ssh -t <host> "zmx attach <session>"
  └── always/trap cleanup: clear zmx_host + zmx_session
```

The local function must use an `always`/trap-style cleanup so cleanup occurs after successful disconnect, `exit` from the zmx session, rejected SSH connection, or an interrupted client command. If the entire Kitty window exits, there is no remaining window on which stale metadata matters.

This replaces remote OSC lifecycle ownership. In particular, `zmx-attach` must no longer emit a set or clear sequence.

### Security and quoting

The implementation must pass host and session values as safely quoted SSH arguments/remote command arguments. Layout files and fzf selections are input, not shell source. Do not interpolate raw session names into `zsh -c '…'` strings.

## `zx`: local picker, then `zp`

`zx` currently invokes a remote `zmx-pick` shell helper and learns the final session through remote OSC. Remove that helper.

The new `zx` flow is:

1. Resolve or explicitly accept a host locally.
2. Query that host from the local machine, without attaching a terminal client:
   ```text
   ssh -T <host> zmx ls --short
   ```
3. Present the returned names in the local `fzf` picker.
4. Preserve the current picker behavior for a typed new session name, if desired.
5. Invoke:
   ```text
   zp --host <selected-host> --session <selected-session>
   ```

The picker itself and all Kitty metadata management now stay local. `zx` has no special metadata lifecycle; it delegates entirely to `zp`.

If richer picker rows are wanted, fetch and parse `zmx list` locally, but keep the selected value as an exact session name. `zmx ls --short` is preferable when only the name is required because it avoids depending on the display format of the detailed listing.

## Delete the remote attach/picker helpers

Remove from `config/zsh/zmx.zsh`:

- `zmx-attach`
- `zmx-pick`
- all comments describing remote OSC lifecycle management

Remove the `source ~/.config/zsh/zmx.zsh; zmx-attach …` and `zmx-pick` `RemoteCommand` constructions. `zp` can invoke `zmx attach` directly through SSH.

The remaining remote-facing helpers, such as `zk` and `zka`, may remain because they operate inside a zmx session through the first-class `ZMX_SESSION` environment variable. They are unrelated to Kitty pane management.

## Smart splits

`smart_split.py` should use the complete connection descriptor:

```text
if zmx_host and zmx_session:
    launch a sibling running: zp --host <zmx_host>
else:
    launch --cwd=current
```

A zmx-managed split deliberately opens a **new** remote zmx session on the same host. It does not duplicate the current session and does not claim to preserve its live remote CWD.

As defense in depth, the kitten can treat metadata as inactive when the focused window no longer has a live local SSH client belonging to managed `zp`. This protects against an extraordinary failed cleanup, but must not be used to discover arbitrary direct `zmx attach` sessions.

## Remove detach-specific marker behavior

The dedicated detach behavior is redundant with closing the Kitty pane. Remove:

- the `zmx_detach_session` action alias;
- `--when-focus-on var:zmx_session` behavior;
- the zmx-mode `d` mapping and its fallback/commentary.

`cmd+shift+p`, then `x`, remains the one pane-closing operation. `shift+d` may remain only if dropping the shared SSH ControlMaster is still a desired explicit "detach all" action; it must not depend on per-window zmx metadata.

## Layout format and restore

### Persist versioned managed connections

Replace the session-only record with a versioned descriptor, for example:

```json
{
  "version": 2,
  "tab_title": "work",
  "layout": "splits",
  "windows": [
    {
      "kind": "zmx",
      "connection": {
        "host": "workspace-dyfontana",
        "session": "p103730"
      },
      "title": "api"
    }
  ]
}
```

`zls` must save a zmx connection only when both local Kitty variables are present. It should not save a stale one-variable record as a valid managed connection.

The local Kitty `.cwd` may be retained only as a local-pane detail. It must not be documented or used as the remote zmx session CWD.

### Deterministic restore

`zlr` restores a zmx window with:

```text
zp --host <connection.host> --session <connection.session>
```

It must not call the interactive `_zmx_host` path for a version-2 record. Missing/invalid host or session metadata should produce a visible restore error instead of opening an arbitrary shell or picker.

Old session-only layouts cannot be restored deterministically on a multi-host setup. Treat them as legacy input: reject them with a migration message, or require a user-selected host once for the entire layout. Do not silently guess.

## Direct zmx CLI semantics

This redesign intentionally sets a clear boundary:

```text
zp / zx / smart split / zlr  → managed pane
ssh host; zmx attach name    → unmanaged pane
```

The direct CLI path retains native zmx behavior and Kitty SSH-kitten behavior, but it has no `zmx_host`/`zmx_session` metadata. Therefore it does not participate in managed smart splits or layout save/restore.

This is preferable to a fragile zsh `preexec` parser that tries to recognize every spelling of `zmx attach`, and avoids aliasing or wrapping the `zmx` command.

A future upstream zmx feature could make direct CLI use managed without aliases: `zmx attach` itself could emit an opt-in terminal-side lifecycle event before taking over the terminal and after it exits. zmx currently has no plugin or hook API for this. Such a feature would still need a local strategy for preserving the user-facing SSH alias used to reach the host.

## Current-directory limitation

Host/session metadata solves restoration and same-host splitting, not same-directory splitting.

The zmx session list exposes a session start directory, not its current shell/process directory. The current directory may change after session creation, and querying it by injecting `pwd` through the session would interfere with editors, REPLs, and other foreground processes.

Do not add `--cwd=current` to the managed split branch as a claimed fix: it would affect the new local launcher shell, not the remote zmx session. A correct implementation requires either:

1. a zmx API that reports a session's current process CWD;
2. zmx support for forwarding trusted remote CWD reports; or
3. an explicit product choice to start new sessions in the saved start directory instead.

Until then, new managed zmx splits should correctly promise only "new session on the same host."

## Implementation sequence

1. Add small local helpers to set and clear the two Kitty variables by window ID.
2. Redesign `zp` around explicit host/session arguments and local `always`/trap cleanup.
3. Rewrite `zx` to query `zmx ls --short` over SSH, choose locally, and delegate to `zp`.
4. Delete `zmx-attach` and `zmx-pick`; remove remote OSC lifecycle logic.
5. Update `smart_split.py` to require `zmx_host` and `zmx_session`, and launch `zp --host …`.
6. Remove the detach-specific key mapping and marker condition.
7. Upgrade `zls`/`zlr` to version-2 host/session connection records and deterministic restore.
8. Update the README to distinguish managed `zp`/`zx` panes from unmanaged direct zmx CLI use.
9. Optionally add the local foreground-process liveness guard after the primary lifecycle is working.

## Acceptance checks

- `zp --host host-a --session test` sets both metadata values while connected.
- `exit` from that zmx session returns to the local shell and clears both values before another split is created.
- Failed authentication, remote exit, and an interrupted SSH client clear both values.
- A subsequent smart split after cleanup takes the ordinary `--cwd=current` branch rather than calling `zp`.
- `zx` selects an existing or new session locally, then produces the same metadata and behavior as `zp`.
- `ssh host; zmx attach test` does not set managed metadata and does not interfere with normal Kitty splitting.
- `zls` stores host and session for each managed pane.
- `zlr` restores a multi-host layout without invoking a host picker and connects every pane to its saved host/session.
- A saved remote zmx pane does not claim that its local Kitty `.cwd` is the remote session's current directory.
