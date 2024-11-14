# Basic packages
sudo pacman -S --noconfirm --needed bat btop chezmoi curl eza fastfetch fd fzf \
go-yq jq meld neovim ripgrep starship tealdeer tmux unzip wget zellij zoxide

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
