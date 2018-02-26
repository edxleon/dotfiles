#!/bin/bash

params="-sf"
script_home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install fish-shell
sudo apt-add-repository ppa:fish-shell/release-2 -y
sudo apt-get update -y
sudo apt-get install fish -y

# Install fisherman (Plugin Manager for fish)
if [ ! -f $HOME/.config/fish ]; then
    curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
    fish ./plungin_install.fish
fi

# Start Plugin Installer Script
fish $script_home/plugin_install.fish

# Symlinks
ln $params $script_home/fish_user_key_bindings.fish $HOME/.config/fish/functions/fish_user_key_bindings
ln $params $script_home/config.fish $HOME/.config/fish/config.fsh