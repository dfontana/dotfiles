# kitty title prefix for zmx
Context: `zmx-attach` already sends Kitty's OSC 1337 `SetUserVar=zmx_session`, preserving the remote session identity even when applications such as Helix replace the title. We want title bars to show `[$ZMX_SESSION] ` before Kitty's normal dynamic title only for those windows.
Blocker: `window_title_template` cannot interpolate user variables; `set-user-vars` only supports remote-control matching. `set-window-title --temporary` lets applications replace the prefix, while its permanent mode prevents application titles entirely.
Ask: Decide whether Kitty's `window_title_bar.py` custom-title hook (which can read the user var and return the normal title with a prefix) is an acceptable minimal extension, and verify it has no local-title regressions before enabling it.

# kitty.zsh split storage
Context: Kitty has a keybind setup to save and restore layouts, but it doesn't store the actual split layout and sizes so restoring just stacks the panes. Ideally we restore the actual layout of the panes, in addition to the panes themselves.
Ask: Identify the complexity in restoring pane layout and integrate if deemed simple enough. Should only need edits to kitty.zsh

# kitty keys.conf modal mode
Context: Kitty supports modal keybinds just like zellij, which the current keybinds take inspiration from. https://sw.kovidgoyal.net/kitty/mapping/#modal-mappings. We need some way to display the current mode succinctly, which custom tab titles might work (but need to avoid losing the mode on tab rename, so likely not best). https://github.com/kovidgoyal/kitty/discussions/7294
 (maybe best to implement a kitten that wraps the existing tab_bar and floats the information on the right side of the bar).
Ask: Modal bindings are setup and there's feedback in the tab bar on which mode is active, on the right side.

# zmx.zsh wrapper cli?
Context: There's a number of small helpers now (zp, zmx-pick, zx, zk, zka, etc) which makes it less than ideal for memorizing them all. Especially since zp, zx, and zmx-pick overlap. Ideally we create a small utility to wrap all this functionality into a CLI, so it's easier to discover and interact with the commands.
Ask: A single entrypoint to all these commands, with tab completion support.
