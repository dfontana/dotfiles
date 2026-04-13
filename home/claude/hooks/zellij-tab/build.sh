#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugin"
INSTALL_DIR="$HOME/.config/zellij/plugins"

# Prefer the post-1.78 target name; fall back for older toolchains.
if rustup target list --installed 2>/dev/null | grep -q "wasm32-wasip1"; then
  TARGET="wasm32-wasip1"
elif rustup target list --installed 2>/dev/null | grep -q "wasm32-wasi"; then
  TARGET="wasm32-wasi"
else
  # Try to install the modern target.
  TARGET="wasm32-wasip1"
  echo "Installing Rust target $TARGET..."
  rustup target add "$TARGET"
fi

WASM_OUT="$PLUGIN_DIR/target/$TARGET/release/zellij_claude_tab.wasm"

cd "$PLUGIN_DIR"
cargo build --release --target "$TARGET"

mkdir -p "$INSTALL_DIR"
cp "$WASM_OUT" "$INSTALL_DIR/zellij-claude-tab.wasm"
echo "Plugin installed to $INSTALL_DIR/zellij-claude-tab.wasm"
echo "Restart Zellij to activate."
