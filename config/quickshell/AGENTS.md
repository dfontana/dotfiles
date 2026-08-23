# Quickshell visual verification

Quickshell reloads this configuration when its running `qs -p quickshell/home`
process detects an edit. Do not launch an additional `qs` process while
validating a live session.

## Capture the bar

Capture the full virtual desktop, then crop the primary monitor's bar:

```sh
mkdir -p /tmp/quickshell-preview
grimblast save screen /tmp/quickshell-preview/current.png
magick /tmp/quickshell-preview/current.png \
  -crop 2560x100+0+235 /tmp/quickshell-preview/dp1-bar.png
```

The current layout puts `DP-2` 240px above `DP-1`, so `DP-1` starts at y=240
in a full-desktop capture; the crop begins five pixels above its bar. `DP-2`
is rotated and its bar can be cropped with:

```sh
magick /tmp/quickshell-preview/current.png \
  -crop 1080x100+2560+0 /tmp/quickshell-preview/dp2-bar.png
```

Confirm the monitor geometry before relying on those offsets:

```sh
hyprctl monitors -j | jq '[.[] | {name, x, y, width, height, scale, transform}]'
```

## Simulate hover

Hyprland's Lua dispatcher can move the pointer to a bar control. Save and
restore its position so the verification does not disturb the desktop. This
example hovers the `DP-1` home button, waits for the power drawer animation,
and captures it:

```sh
cursor="$(hyprctl cursorpos -j)"
restore_x="$(jq -r '.x' <<<"$cursor")"
restore_y="$(jq -r '.y' <<<"$cursor")"

hyprctl dispatch 'hl.dsp.cursor.move({ x = 25, y = 22 })'
sleep 0.5
grimblast save screen /tmp/quickshell-preview/power-drawer-hover.png

hyprctl dispatch "hl.dsp.cursor.move({ x = $restore_x, y = $restore_y })"
```

The coordinates are global compositor coordinates. For example, x=1280,
y=22 hovers the centered `DP-1` workspace switcher. Re-check monitor geometry
if the display layout changes. Do not use legacy `hyprctl dispatch movecursor`
syntax: this Hyprland session uses Lua dispatchers.
