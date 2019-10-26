# dotfiles
Stores configurations related to development environment.

## Prerequisites
- oh-my-zsh is expected to already be installed.

## Using

- Run `./update_links.sh` from within this directory. No it's not perfect, but it will link things.
- For the solarized theme:

    ```
    git clone https://github.com/altercation/vim-colors-solarized.git
    cd vim-colors-solarized/colors
    mv solarized.vim ~/.vim/colors/
    ```

- For vim to copy to system clipboard (and paste from it):

    ```
    # Have the build deps you need for this to work (libncurses* may not be needed)
    # Checkinstall is so we can install this as a system package for apt to manage rather than the void
    sudo apt install libncurses5-dev libncursesw5-dev xorg-dev checkinstall

    # Configure the install
    git clone <vim repo on github>
    cd vim
    ./configure \
        --enable-pythoninterp=dynamic \
        --enable-rubyinterp=dynamic \
        --enable-cscope \
        --enable-gui=auto \
        --enable-gtk2-check \
        --enable-gnome-check \
        --with-features=huge \
        --with-x \

    make
    sudo cleaninstall
    vim --version  # Should be stated as built by you
    ```


## Notes:

- `<leader>p` to prettier
- `s<char><char>` to sneak forwards. `S` to backwards. `;` to move to next match.
