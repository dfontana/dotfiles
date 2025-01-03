#!/bin/bash
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

LINK_FONTS=${LINK_FONTS:-0}
LINK_FAN=${LINK_FAN:-0}
LINK_LINUX=${LINK_LINUX:-0}
LINK_GTK=${LINK_GTK:-0}

# Link Home
echo "Linking Home"
for item in home/*; do
  cln=${item#"home/"}
  link $item "$HOME/.$cln"
done

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
  mkdir -p "$HOME/$font_dir"
  for item in fonts/ttfs/*.ttf; do
    cln=${item#"fonts/ttfs/"}
    link $item "$HOME/$font_dir/$cln"
  done
  echo "Fonts linked, don't forget to run: fc-cache -v"
else
  echo "Will not link Fonts; use LINK_FONTS=1"
fi
