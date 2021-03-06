#!/bin/sh
for item in .*; do
    if [ "$item" != "." ] && [ "$item" != ".." ] && [ "$item" != ".git" ]; then
        if [ "$item" = ".zsh_custom" ]; then
            ln -rns ./$item ~/.oh-my-zsh/custom &> /dev/null
        else
            ln -rns ./$item ~/$item &> /dev/null
        fi

        LINKED=$?

        if [ $LINKED -eq 0 ]; then
             echo "[$item] Linked."
        else
            echo "[$item] Exists."
        fi
    fi
done
