#!/usr/bin/env bash

# Basic packages
sudo pacman -S --noconfirm --needed bat btop chezmoi curl eza fastfetch fd fzf \
  meld neovim ripgrep starship tealdeer tmux unzip vim wget zoxide

# Git tools
sudo pacman -S --noconfirm --needed git git-delta github-cli lazygit

# Shells
sudo pacman -S --noconfirm --needed bash bash-completion
#sudo pacman -S --noconfirm --needed zsh zsh-completions
sudo pacman -S --noconfirm --needed fish

# Flatpak
sudo pacman -S --noconfirm --needed flatpak

# Pacman stuff
sudo pacman -S --needed --noconfirm pacman-contrib

sudo systemctl enable paccache.timer

# Only run this if on pure archlinux
# os_release=$(grep -e "^ID=" /etc/os-release | cut -d'=' -f2)
# if [ ${os_release} = "arch" ]; then
# ## pacman hook for grub update
# 	if [ ! -d /etc/pacman.d/hooks ]; then
#   		sudo mkdir -p /etc/pacman.d/hooks
# 	fi

# 	if [ ! -f /etc/pacman.d/hooks/91-update-grub.hook ]; then
#   		cat <<EOF | sudo tee -a /etc/pacman.d/hooks/91-update-grub.hook
# [Trigger]
# Type = File
# Operation = Install
# Operation = Upgrade
# Operation = Remove
# Target = usr/lib/modules/*/vmlinuz

# [Action]
# Description = Updating grub configuration ...
# When = PostTransaction
# Exec = /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
# EOF
# 	fi
# fi

# Install yay AUR helper if not already present
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm base-devel
  git clone https://aur.archlinux.org/yay-bin.git
  cd yay-bin
  makepkg -si
  # Cleanup ./yay-bin directory after package is installed
  cd ..
  rm -rf yay-bin
fi

if ! command -v arch-update &>/dev/null; then
  echo "Install arch-update from AUR"
  yay -S arch-update
  # Add the arch-update-tray.desktop app in your XDG Autostart directory
  if [ ! -d "$HOME/.config/autostart" ]; then
    mkdir -pv "$HOME/.config/autostart"
  fi
  cp -v /usr/share/applications/arch-update-tray.desktop "$HOME/.config/autostart/"

  echo "Enable the arch-update systemd timer"
  systemctl --user enable --now arch-update.timer
fi

echo "Install Uncomplicated Firewall"
sudo pacman -S --needed --noconfirm ufw gufw

# Add current user to sudoers
#echo "${USER} ALL=(ALL:ALL) ALL" | sudo tee /etc/sudoers.d/${USER}

echo "Installing zram-generator"
sudo pacman -S --needed --noconfirm zram-generator
echo "Generating default configuration file /etc/zram-generator.conf"
cat <<EOF | sudo tee -a /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram / 2, 4096)
EOF
echo "Starting ZRAM device"
sudo systemctl daemon-reload
sudo systemctl start /dev/zram0
echo "You can restart your computer to enable zram swap"
