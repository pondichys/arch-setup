 # Install Arch Linux with BTRFS, snapper and optional full disk encryption

Before pacstrap

Edit /etc/pacman.conf to enable parallel downloads

Use reflector to generate a list of mirrors based on your contry

reflector --country <country> --protocol https --sort rate

``` bash
# Install not so minimal KDE desktop
# plasma-desktop : minimal KDE
# konsole : a terminal
# kscreen : KDE screen and display manager
# plasma-nm : NetworkManager add-on
# plasma-pa : sound management add-on

sudo pacman -S plasma-desktop konsole kscreen plasma-nm plasma-pa
```


