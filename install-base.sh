# Basic packages
sudo pacman -S --noconfirm --needed bat btop chezmoi curl eza fastfetch fd fzf \
go-yq jq meld neovim ripgrep starship tealdeer tmux unzip vim wget zellij zoxide

# Git tools
sudo pacman -S --noconfirm --needed git git-delta github-cli lazygit

# Shells
sudo pacman -S --noconfirm --needed bash bash-completion
sudo pacman -S --noconfirm --needed fish

# Flatpak
sudo pacman -S --noconfirm --needed flatpak

# Pacman stuff
sudo pacman -S --needed --noconfirm pacman-contrib
sudo systemctl enable paccache.timer
## pacman hook for grub update
if [ ! -d /etc/pacman.d/hooks ]; then
  sudo mkdir -p /etc/pacman.d/hooks
fi

if [ ! -f /etc/pacman.d/hooks/91-update-grub.hook ]; then
  cat <<EOF | sudo tee -a /etc/pacman.d/hooks/91-update-grub.hook
[Trigger]
Type = File
Operation = Install
Operation = Upgrade
Operation = Remove
Target = usr/lib/modules/*/vmlinuz

[Action]
Description = Updating grub configuration ...
When = PostTransaction
Exec = /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
  EOF
fi

# Firewall
sudo pacman -S --needed --noconfirm ufw
