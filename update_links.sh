#!/bin/bash
pwd=$(pwd)

function link {
  local item=$1
  local dest=$2
  local force=${3:-1}

  if [ $force -eq 0 ]; then
    echo "\t Forcing..."
    ln -nsf $pwd/$item $dest &> /dev/null
  else
    ln -ns $pwd/$item $dest &> /dev/null
  fi

  
  LINKED=$?
  if [ $LINKED -eq 0 ]; then
     echo "\t [$item] Linked to $dest"
  else
     echo "\t [$item] Exists at $dest"
  fi
}

LINK_FAN=${LINK_FAN:-0}
LINK_LVIM=${LINK_LVIM:-0}

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

# Link Lvim
echo "Linking Lvim"
if [ $LINK_LVIM -eq 1 ]; then
  for item in lvim/*; do
    git check-ignore -q $item
    if [ $? -eq 1 ]; then
      link $item "$HOME/.config/lvim/" 0
    fi
  done
else
  echo "\t Not linking, pass LINK_LVIM=1 if desired"
fi

# Link Fan Control
echo "Linking FanControl"
if [ $LINK_FAN -eq 1 ]; then
  for item in fancontrol/systemd/*.service; do
    link $item "/etc/systemd/system/"
  done
else
  echo "\t Not linking, pass LINK_FAN=1 if desired"
fi

