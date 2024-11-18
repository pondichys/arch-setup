#!/usr/bin/env bash
# Remove power-profiles-daemon to avoid conflict with tlp
sudo pacman -R power-profiles-daemon
# Install tlp 
# https://wiki.archlinux.org/title/TLP
sudo pacman -S --needed --noconfirm tlp

# Enable and start tlp service
sudo systemctl enable tlp.service
sudo systemctl start tlp.service

# Mask systemd-rfkill service and socket (see Arch Wiki)
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket

