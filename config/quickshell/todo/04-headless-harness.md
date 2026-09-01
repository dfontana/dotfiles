# Headless Quickshell verification harness

- **Status:** planned; no implementation started
- **Likely files:** a small harness under `config/quickshell/` or an appropriate
  mise task, plus only the smallest dependency declaration if needed
- **Dependency:** Fedora's `grim` package

## Goal

Create a repeatable Hyprland headless-output harness that renders the existing
Quickshell bar, drives a bar hover state, and captures the result as an image.
The harness is for visual and interaction verification; it must not require a
physical display or a separate Quickshell configuration.

## Expected flow

1. Create a named headless output with `hyprctl`:

   ```sh
   hyprctl output create headless QS-HEADLESS
   hyprctl keyword monitor QS-HEADLESS,1280x720@60,0x0,1
   ```

   Confirm the resulting geometry with:

   ```sh
   hyprctl monitors -j | jq '[.[] | {name, x, y, width, height, scale}]'
   ```

2. Let the existing `shell.qml` render the bar normally. It already creates a
   `Bar` variant for every entry in `Quickshell.screens`, so the harness must
   not select or hard-code a particular display.

3. Drive hover with the session's current Lua dispatcher syntax. Move away
   from the target control first, then move onto it so the QML `MouseArea` or
   `HoverHandler` receives an enter event:

   ```sh
   hyprctl dispatch 'hl.dsp.cursor.move({ x = 200, y = 16 })'
   ```

   Coordinates are global Hyprland layout coordinates. Save and restore the
   original cursor position when the harness finishes.

4. Wait for Quickshell to render the hover state and any animation, then capture
   the headless output:

   ```sh
   grim -o QS-HEADLESS /tmp/quickshell-headless-hover.png
   ```

5. Remove the output in cleanup:

   ```sh
   hyprctl output remove QS-HEADLESS
   ```

The harness must follow `config/quickshell/AGENTS.md`: do not launch a second
`qs` process while the existing `qs -p quickshell/home` watcher is running.

## Headless server notes

The harness can eventually run on `kossserver.local` without a physical monitor.
Its Intel IvyBridge HD Graphics 4000 (`i915`) GPU should be sufficient if Mesa
exposes GLES 3.0 or newer; Vulkan is not required. Verify with `eglinfo -B` and
look for the Intel renderer rather than `llvmpipe`.

A direct SSH launch failed because the SSH session was not attached to a
logind seat (`Remote=yes`, `Seat=` empty), not because of the GPU.
`AQ_NO_KMS_REQUIREMENT=1` only relaxes the connected-monitor/KMS requirement;
it does not provide seat access. The eventual setup should install and enable
`seatd`, add the user to the `seat` group, reconnect, and launch Hyprland
through the watchdog with the seatd backend selected:

```sh
sudo dnf install seatd egl-utils
sudo systemctl enable --now seatd
sudo usermod -aG seat koss

LIBSEAT_BACKEND=seatd \
AQ_NO_KMS_REQUIREMENT=1 \
dbus-run-session -- start-hyprland
```

`systemd-logind` should remain installed and running. `seatd` and logind can
coexist, but each compositor session should use one backend consistently:
logind for a normal local/VT session and seatd for this SSH-launched headless
session. Revisit the exact service/session setup when implementing the harness.

## Fedora dependency

`grim` is packaged in Fedora's official repositories under the package name
`grim`:

```sh
sudo dnf install grim
```

On an immutable Fedora installation, use the corresponding host package
installation method (for example, `rpm-ostree install grim`). `grimblast` is
not required; the harness captures the named output directly with `grim`.

## Acceptance checks

- A named headless output is created at a deterministic resolution and removed
  on success, failure, or interruption.
- The unmodified all-screen bar appears on the headless output.
- `hyprctl dispatch` produces the expected hover/enter state without
  `wlrctl` or `wdotool`.
- The screenshot contains the rendered hover state after animation settles.
- The original cursor position is restored.
- The harness works without starting a second Quickshell process and records
  useful diagnostics when the output, bar, or screenshot is unavailable.

## Progress log

- 2026-08-31: Harness requirements recorded; implementation and live
  verification remain pending.
