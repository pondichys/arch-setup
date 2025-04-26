#!/usr/bin/env bash

sudo pacman -S --needed --noconfirm plasma-desktop kdeplasma-addons sddm \
  ark kscreen konsole kde-system-meta print-manager sddm-kcm \
  plasma-pa plasma-nm plasma-firewall

# kwallet utilities
sudo pacman -S --needed --noconfirm kwallet-pam kwalletmanager
