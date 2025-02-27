# Install Arch Linux with EXT4, disk encryption and secure boot on UEFI machine

## Context
This documentation describes a simple and relatively secure Arch Linux installation.

- Simple: I use a basic partitioning layout and the good old EXT4 file system.
- Secure: I encrypt everything except the EFI boot partition. To protect from EFI partition manipulation I decided to enable secure boot.

### A note on secure boot
At the time of writing this documentation, you must disable secure boot to be able to install Arch Linux.

## Download latest arch linux iso
Download it from [Arch Linux web site](https://archlinux.org/download)

## Prepare USB installation media
- Write the downloaded ISO file to an USB stick with [Rufus](https://rufus.ie/en/), [Balena Etcher](https://etcher.balena.io) or [Fedora Media Writer](https://flathub.org/apps/org.fedoraproject.MediaWriter).
- Or use [Ventoy](https://www.ventoy.net/en/index.html)

## Boot on USB key
Check your motherboard instructions to select the boot device and boot on the USB key containing the arch linux ISO.

## Configure keyboard layout (optional)
Enable your keyboard layout if using non english layouts. I'm using belgian layout.

```bash
# Belgian layout
loadkeys be-latin1
```

## Configure network
If using ethernet, everything should work out of the box.

If using wifi, use `iwctl` to configure your wifi connection.

```bash
iwctl

# Show the list of device. Most of the time it should be wlan0
device list

# Connect to your wifi network
station connect <your_SSID>
```

In both cases, check your connectivity to ensure you can reach the arch linux repositories.

```bash
ping archlinux.org
```

## Enable SSH (optional)
This allows you to install from another remote computer and just use copy / paste for the commands.

```bash
systemctl start sshd.service

# Don't forget to setup a root password to connect through SSH
passwd
```

## Configure partitions

```bash
# Identify your disk device where you want to install arch linux
lsblk

# Set the disk device you want to use for installation as an environment variable
# for a kvm/qemu vm
export INSTALL_DISK=/dev/vda
# for a SATA ssd/hdd
# export INSTALL_DISK=/dev/sda
# for an NVME SSD
# export INSTALL_DISK=/dev/nvme0n1

# Zap the hard drive
## !!!!!!! This action deletes everything on the selected device !!!!!!!
sgdisk -Z ${INSTALL_DISK}

# Create a first partition for EFI with a size of 1 GB min
# We will store kernels on this partition so it should be correctly sized
sgdisk -n1::+1G -t1:EF00 -c1:'ESP' ${INSTALL_DISK}
# Create a second partition for Arch Linux install
sgdisk -n2:: -t2:8300 -c2:'ARCHLINUX' ${INSTALL_DISK}
# Check the results
sgdisk -p ${INSTALL_DISK}

# List the block devices
lsblk
# Identify both partitions and set environment variables for them
export EFI_PART=/dev/vda1
export LINUX_PART=/dev/vda2
```

## LUKS encryption
Caution: I use LUKS2 header and thus argon2id pbkdf type. This is possible because I use systemd-boot bootmanager. If you want to switch to grub later on, add the --pbkdf pbkdf2 option to the cryptsetup format command below to ensure support of grub.

```bash
cryptsetup luksFormat --type luks2 ${LINUX_PART}
# Type YES to continue
# Enter your passphrase 2 times

# Open the encrypted device
cryptsetup luksOpen ${LINUX_PART} cryptroot
```

## Format the partitions

```bash
mkfs.vfat -F32 -n "EFI" ${EFI_PART}
mkfs.ext4 -L ROOT /dev/mapper/cryptroot
```

## Create and mount encrypted root partition

```bash
mount /dev/mapper/cryptroot /mnt
```

## Create and mount the EFI partition

```bash
mkdir -pv /mnt/boot
# Mount /boot
mount -o noatime ${EFI_PART} /mnt/boot

# Check that everything looks ok
df -h
```

## Install the base system

Tune the system for optimized download

```bash
# Set ParallelDownloads to a reasonable number according to your internet connection performance
sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Use best mirrors based on your location
reflector --country <your country name> --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# If you use AMD CPU
pacstrap -K /mnt base base-devel linux linux-headers linux-firmware cryptsetup neovim networkmanager git e2fsprogs dosfstools sbctl sudo amd-ucode
# If you use Intel CPU
# pacstrap -K /mnt base base-devel linux linux-headers linux-firmware cryptsetup neovim networkmanager git e2fsprogs dosfstools sbctl sudo intel-ucode

```

## Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

## System configuration

```bash
# Use timedatectl to ensure system clock is accurate
timedatectl set-ntp true

# CHROOT into the newly installed system
arch-chroot /mnt

# Edit /etc/locale.gen and uncomment your locales
# I use en_US.UTF-8 UTF-8
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
# Regenerate the locales
locale-gen

# Configure console keymap, timezone and hostname
systemd-firstboot --keymap=be-latin1 --locale=en_US.UTF-8 \
	--locale-messages=en_US.UTF-8 --timezone="Europe/Brussels" \
	--hostname="arch-vm" --welcome=false

# Add user
USER=<your_user_name>
useradd -m -g users -G wheel -s /bin/bash $USER
passwd $USER
echo "$USER ALL=(ALL) ALL" >> /etc/sudoers.d/$USER 
chmod 0440 /etc/sudoers.d/$USER

# Setup mkinitcpio to handle encryption correctly
# I use a systemd based initramfs so the HOOKS section must be equal to
# HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)

# Install systemd-boot bootloader
bootctl install

# Generate initramfs and kernel images
mkinitcpio -P

# Configure systemd-boot
# Main loader config
cat <<EOF > /boot/loader/loader.conf
default arch.conf
timeout 4
console-mode max
EOF

# Entry for arch standard kernel
cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value $LINUX_PART)=cryptroot root=/dev/mapper/cryptroot rw
EOF

# Entry for fallback
cat <<EOF > /boot/loader/entries/arch-fallback.conf
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux-fallback.img
options rd.luks.name=$(blkid -s UUID -o value $LINUX_PART)=cryptroot root=/dev/mapper/cryptroot rw
EOF

# Setup root password
passwd

# Check secure boot status
# setup mode MUST be enabled
sbctl status

# Create secure boot keys
sbctl create-keys
# Enroll your keys and the ones from Microsoft to avoid unpleasant surprises ...
sbctl enroll-keys -m
# Sign systemd bootlader
sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi

# Sign the kernel and cpu microcode
sbctl sign -s /boot/vmlinuz-linux

# Reinstall the bootlader
bootctl install
# Verify the setup - everything should be ok
sbctl verify

# Exit chroot and reboot
exit
umount -R /mnt
reboot
```

## Install KDE Plasma desktop environment

```bash
sudo pacman -S plasma-desktop sddm kde-system-meta konsole
```

## Enable multithread compilation of AUR packages
Edit the file `/etc/makepkg.conf` and set `MAKEFLAGS="-j<number of threads>"`

## Boot in recovery mode
Insert an USB device with arch linux ISO and boot on it like for the installation process.

Setup the keyboard if needed

Decrypt the LUKS device

```bash
cryptsetup luksOpen /dev/vda2 cryptroot
```

Mount the file systems

```bash
mount /dev/mapper/cryptroot /mnt
mount /dev/vda1 /mnt/boot
```

Enter in CHROOT and fix the system

```bash
arch-chroot /mnt
```
