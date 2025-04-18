#!/usr/bin/env bash
sudo pacman -S --needed --noconfirm sane sane-airscan simple-scan

# Add user to scanner group
sudo usermod -aG scanner $USER

# Printing
sudo pacman -S --needed --noconfirm cups cups-pdf avahi nss-mdns

sudo systemctl enable --now cups.socket
# Enable avahi hostname resolution
# Edit /etc/nssswitch.conf and replace the line
# hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
# by 
# hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns
sudo systemctl enable --now avahi-daemon.service
