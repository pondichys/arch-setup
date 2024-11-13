 # Install Arch Linux with BTRFS, snapper and optional full disk encryption

Before pacstrap

Edit /etc/pacman.conf to enable parallel downloads

Use reflector to generate a list of mirrors based on your contry

reflector --country <country> --protocol https --sort rate

sudo pacman -S plasma-desktop konsole plasma-nm plasma-pa
