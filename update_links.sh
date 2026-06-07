#!/bin/bash
# set -euo pipefail
pwd=$(pwd)

function link {
  local item=$1
  local dest=$2
  local force=${3:-1}

  if [ $force -eq 0 ]; then
    echo -e "\tForcing..."
    ln -nsf "$pwd/$item" "$dest" &> /dev/null
  else
    ln -ns "$pwd/$item" "$dest" &> /dev/null
  fi

  
  LINKED=$?
  if [ $LINKED -eq 0 ]; then
     echo -e "\t[$item] Linked to $dest"
  else
     echo -e "\t[$item] Exists at $dest"
  fi
}

# Idempotently ensure a line exists in a file.
# Usage: ensure_line <file> <line> [position]   position: append (default) | prepend
function ensure_line {
  local file=$1
  local line=$2
  local position=${3:-append}

  mkdir -p "$(dirname "$file")"
  if [ -f "$file" ] && grep -qF -- "$line" "$file"; then
    echo -e "\t[$file] Already present"
    return
  fi
  if [ "$position" = "prepend" ] && [ -f "$file" ]; then
    printf '%s\n\n%s' "$line" "$(cat "$file")" > "$file"
  else
    printf '%s\n' "$line" >> "$file"
  fi
  echo -e "\t[$file] Added line"
}

LINK_FONTS=${LINK_FONTS:-0}
LINK_FAN=${LINK_FAN:-0}
LINK_LINUX=${LINK_LINUX:-0}
LINK_GTK=${LINK_GTK:-0}

# Link Home
echo "Linking Home"
for item in home/*; do
  cln=${item#"home/"}
  # These are runtime dirs that should be linked individually
  if [[ "$cln" = "claude" || "$cln" = "ssh" ]]; then
    echo "Linking "$cln" (individual items)"
    for subitem in home/"$cln"/*; do
      subcln=${subitem#"home/$cln/"}
      link $subitem "$HOME/.$cln/$subcln"
    done
    continue
  fi
  link $item "$HOME/.$cln"
done

echo "Including ssh config"
ensure_line "$HOME/.ssh/config" "Include ~/.ssh/config.local" prepend

echo "Ensuring mise shims on PATH for all zsh invocations"
# Static, fork-free, portable (mise's shims dir is ~/.local/share/mise/shims on
# macOS and Linux). .zshenv is the only file every zsh reads, so non-interactive
# `zsh -c` and zsh scripts resolve mise tools; bash shebang scripts inherit PATH.
mise_shims='case ":$PATH:" in *":$HOME/.local/share/mise/shims:"*) ;; *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;; esac'
ensure_line "$HOME/.zshenv" "$mise_shims"

echo "Linking .config"
for item in config/*; do
  cln=${item#"config/"}
  link $item "$HOME/.config/$cln"
done

if [ $LINK_LINUX -eq 1 ]; then
  echo "Linking bonus bins"
  mkdir -p $HOME/.local/bin
  for item in bin/*; do
    cln=${item#bin/}
    link $item "$HOME/.local/bin/$cln"
  done

  echo "Linking bonus .desktop files"
  mkdir -p $HOME/.local/share/applications
  for item in desktops/*; do
    cln=${item#desktops/}
    link $item "$HOME/.local/share/applications/$cln"
  done

  echo "Linking user systemd units"
  mkdir -p "$HOME/.config/systemd/user"
  for item in systemd/user/*.service; do
    cln=${item#systemd/user/}
    link $item "$HOME/.config/systemd/user/$cln" 0
  done
else
  echo "Will not link linux specifics; use LINK_LINUX=1"
fi

if [ $LINK_GTK -eq 1 ]; then
  echo "Linking icons"
  git submodule init
  for item in gtk/icons/*-icons; do
    pfx=${item#gtk/icons/}
    cln=${pfx%-icons}
    link $item "$HOME/.local/share/icons/$cln"
    # Update GTK caches
    gtk4-update-icon-cache "$HOME/.local/share/icons/$cln"
  done
else
  echo "Will not link icons; use LINK_GTK=1"
fi

# Link Fan Control
if [ $LINK_FAN -eq 1 ]; then
  echo "Linking FanControl"
  for item in fancontrol/systemd/*.service; do
    link $item "/etc/systemd/system/"
  done
else
  echo "Will not link FanControl; use LINK_FAN=1"
fi

if [ $LINK_FONTS -eq 1 ]; then
  echo "Linking Fonts"
  font_dir='.local/share/fonts/IosevkaCustom Nerd Font Mono'
  icon_font_dir='.local/share/fonts/Iosevka Nerd Font'
  mkdir -p "$HOME/$font_dir"
  for item in fonts/ttfs/*.ttf; do
    cln=${item#"fonts/ttfs/"}
    link $item "$HOME/$font_dir/$cln"
  done
  mkdir -p "$HOME/$icon_font_dir"
  item='IosevkaNerdFont-Regular.ttf'
  for item in fonts/icons/*.ttf; do
    cln=${item#"fonts/icons/"}
    link $item "$HOME/$icon_font_dir/$cln"
  done
  echo "Fonts linked, don't forget to run: fc-cache -v"
else
  echo "Will not link Fonts; use LINK_FONTS=1"
fi
