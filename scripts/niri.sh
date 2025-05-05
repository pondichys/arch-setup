#!/usr/bin/env bash
sudo pacman -S --needed --noconfirm niri mako waybar swaybg swayidle swaylock fuzzel xwayland-satellite cliphist

yay -S --needed --noconfirm wlogout

if [ ! -d "$HOME/.config/systemd/user/niri.service.wants/" ]; then
  echo "Creating service configuration files..."
  mkdir -pv "$HOME/.config/systemd/user/niri.service.wants"
  ln -s /usr/lib/systemd/user/mako.service "$HOME/.config/systemd/user/niri.service.wants/"
  ln -s /usr/lib/systemd/user/waybar.service "$HOME/.config/systemd/user/niri.service.wants/"
fi
