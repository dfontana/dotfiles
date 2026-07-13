# kitty theme.conf for zmx
Context: It's hard to tell the current pane is a remote session over zmx. We should update the window title to conditionally indicate it's a remote session using the ZMX_SESSION variable we use elsewhere in the zmx scripts
Ask: Can identify the zmx session a pane is attached to in the window title, but only when it's a session (otherwise nothing is shown)

# kitty.zsh split storage
Context: Kitty has a keybind setup to save and restore layouts, but it doesn't store the actual split layout and sizes so restoring just stacks the panes. Ideally we restore the actual layout of the panes, in addition to the panes themselves.
Ask: Identify the complexity in restoring pane layout and integrate if deemed simple enough. Should only need edits to kitty.zsh

# kitty keys.conf modal mode
Context: Kitty supports modal keybinds just like zellij, which the current keybinds take inspiration from. https://sw.kovidgoyal.net/kitty/mapping/#modal-mappings. We need some way to display the current mode succinctly, which custom tab titles might work (but need to avoid losing the mode on tab rename, so likely not best). https://github.com/kovidgoyal/kitty/discussions/7294
 (maybe best to implement a kitten that wraps the existing tab_bar and floats the information on the right side of the bar).
Ask: Modal bindings are setup and there's feedback in the tab bar on which mode is active, on the right side.

# kitty smart_split cwd on the remote and/or local
Context: smart_split does not maintain the cwd when launching a split. Ideally this will maintain the cwd when working locally or in a ZMX session over ssh. The shift-split override should remain without cwd.
Ask: Opening a "smart_split" maintains the cwd in the new pane regardless of local or remote connection.

# kitty keys.conf zmx detach
Context: CUrrently detach keybind will close all active connections but in reality we should have `d` detach just that one pane/connection, while all `shift+d` detaches everything. This will require detecting the active pane so we only detach if it's an active zmx session that's focused, otherwise nothing.
Ask: Setup the specified keybind and behavior, identifying how to do this with the focus behavior desired

# zmx.zsh wrapper cli?
Context: There's a number of small helpers now (zp, zmx-pick, zx, zk, zka, etc) which makes it less than ideal for memorizing them all. Especially since zp, zx, and zmx-pick overlap. Ideally we create a small utility to wrap all this functionality into a CLI, so it's easier to discover and interact with the commands.
Ask: A single entrypoint to all these commands, with tab completion support.
