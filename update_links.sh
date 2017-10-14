#!/bin/sh
cd ~/dotfiles || exit
for item in .*; do
    if [ "$item" != "." ] && [ "$item" != ".." ] && [ "$item" != ".git" ]; then
        if [ "$item" = ".zsh_custom" ]; then
            ln -ns ~/dotfiles/$item ~/.oh-my-zsh/custom &> /dev/null
        else
            ln -ns ~/dotfiles/$item ~/$item &> /dev/null
        fi

        LINKED=$?

        if [ $LINKED -eq 0 ]; then
             echo "[$item] Linked."
        else
            echo "[$item] Exists."
        fi
    fi
done
