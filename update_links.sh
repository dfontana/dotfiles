#!/bin/sh
cd ~/dotfiles
for item in .*; do
    if [ $item != "." ] && [ $item != ".." ]; then
        if ln -s ~/dotfiles/$item ~/$item &> /dev/null; then
            echo "[$item] Linked."
        else
            echo "[$item] Exists."
        fi
    fi



done
