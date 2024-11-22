# Install Arch Linux with BTRFS, snapper and optional full disk encryption

## Configure partitions

### LUKS encryption

Create a key file to avoid entering password twice (once to get to grub and once to open the / partition)

```bash
# Switch to root user
sudo -i

# Generate the key file. You can obviously play with settings to harden it more 
dd bs=512 count=4 if=/dev/random iflag=fullblock | install -m 0600 /dev/stdin /etc/cryptsetup-keys.d/root.key

# Add the key file as a LUKS key allowed to open the LUKS device
cryptsetup luksAddKey /dev/sdX# /etc/cryptsetup-keys.d/root.key

# Add the key file to the FILEs section of mkinitcpio configuration. This will embed the file in the initramfs

# Lastly, add the location of the key file as a kernel parameter in /etc/default/grub
cryptkey=rootfs:/etc/cryptsetup-keys.d/root.key

# Regenerate grub configuration and initramfs
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P

```

Before pacstrap

Edit `/etc/pacman.conf` to enable parallel downloads.

Use reflector to generate a list of mirrors based on your contry

reflector --country <country> --protocol https --sort rate




``` bash
# Install not so minimal KDE desktop
# plasma-desktop : minimal KDE
# konsole : a terminal
# kscreen : KDE screen and display manager
# plasma-nm : NetworkManager add-on
# plasma-pa : sound management add-on

sudo pacman -S --needed --noconfirm \
plasma-desktop sddm sddm-kcm \
dolphin ffmpegthumbs \
qt6-multimedia qt6-multimedia-gstreamer qt6-multimedia-ffmpeg \
konsole kscreen plasma-nm plasma-pa plasma-firewall \
ark print-manager spectacle plasma-systemmonitor kwalletmanager
```
## Snapper snapshots

Create a snapper configuration named root for / path

Install `snap-pac` package to automatically create snapshots when a `pacman` transaction is executed.

Reference: [snap-pac documentation](https://barnettphd.com/snap-pac/index.html)

## Enable multithread compilation of AUR packages
Edit the file `/etc/makepkg.conf` and set `MAKEFLAGS="-j<number of threads>"`

