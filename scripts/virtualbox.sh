#!/bin/bash
#set -e

# Install linux headers
# This is required for DKMS modules to compile
sudo pacman -S --needed --noconfirm linux-headers

# Install virtualbox
sudo pacman -S --needed --noconfirm virtualbox virtualbox-host-dkms virtualbox-guest-iso

# resolution issues Jan/2023
# VBoxManage setextradata "Your Virtual Machine Name" "VBoxInternal2/EfiGraphicsResolution" "2560x1440"
# VBoxManage setextradata "Your Virtual Machine Name" "VBoxInternal2/EfiGraphicsResolution" "1920x1080"
# graphical driver - VMSVGA !
# see : https://wiki.archlinux.org/title/VirtualBox#Set_guest_starting_resolution

# Add current user to vboxuser group to enable USB devices enumeration
sudo usermod -aG vboxusers $USER

tput setaf 3
echo "###########################################################################"
echo "########              Please reboot now                            ########"
echo "###########################################################################"
tput sgr0
