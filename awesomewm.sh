#!/usr/bin/env bash

sudo pacman -S --needed --noconfirm awesome
sudo pacman -S --needed --noconfirm xdg-user-dirs

sudo pacman -S --needed --noconfirm lxappearance
sudo pacman -S --needed --noconfirm network-manager-applet polkit-gnome picom blueman

# Other stuff to check
sudo pacman -S --needed --noconfirm pcmanfm-qt lxqt-archiver gvfs flameshot

# Some file system tools that can be handy
sudo pacman -S --needed --noconfirm dosfstools
