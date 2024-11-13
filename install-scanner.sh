sudo pacman -S --needed --noconfirm sane sane-airscan simple-scan

# Add user to scanner group
sudo usermod -aG scanner $USER
