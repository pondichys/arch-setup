CAUTION : this is a WIP and the instructions are not working currently
rEFInd is not able to find the linux kernels as of now


# Install Arch Linux with BTRFS, snapper, REFIND and disk encryption on UEFI machine

## Context
This procedure does not allow a full disk encryption as rEFInd boot manager does not support encrypted /boot partitions like grub does.

To enhance the security of the installation, I enable secure boot

## Download latest arch linux iso

Download it from https://archlinux.org/download

## Prepare USB installation media
- Write the downloaded ISO file to an USB stick with Rufus, Balena Etcher or Fedora USB Writer.
- Or use Ventoy

## Boot on USB key
Check your motherboard instructions to select the boot device and boot on the USB key containing the arch linux ISO.

## Configure keyboard layout (optional)
Enable your keyboard layout if using non english layouts. I'm using belgian or french layouts

```bash
# Belgian layout
loadkeys be-latin1

# French layout
loadkeys fr
```

## Configure network
If using ethernet, everything should work out of the box.

If using wifi, use iwctl to configure your wifi connection.

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
```

## Configure partitions

I prefer a simple partition layout as following

/ : the main partition. Use BTRFS to enable snapshots and subvolumes.
/efi : EFI system partition. Use /efi instead of /boot/efi as mentioned in the [EFI system partition - Typical mount points](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points) section of Arch Wiki. 

Use cfdisk (or fdisk if you prefer) to create your partitions.

```bash
# Identify your disk device where you want to install arch linux
lsblk

# Zap the hard drive
## !!!!!!! This action deletes everything on the selected device !!!!!!!
sgdisk -Z /dev/vda

# For a virtual machine it will be /dev/vda
# For a bare metal machine with nvme /dev/nvme0n1
cfdisk /dev/vda
# Use gpt label type
# /dev/vda1  EFI system  1 GB
# /dev/vda2  Linux Filesystem  the rest (minus swap if you create one)
```

## LUKS encryption
Caution: I use argon2 pbkdf type here as I use reFind as a bootmanager. If you want to switch to grub later on, add the --pbkdf pbkdf2 option to the cryptsetup format command below to ensure support of grub.

```bash
cryptsetup luksFormat /dev/vda2
# Type YES to continue
# Enter your passphrase 2 times

# Open the encrypted device
cryptsetup luksOpen /dev/vda2 cryptroot
```

## Format the partitions

```bash
mkfs.vfat -F32 -n "EFI" /dev/vda1
mkfs.btrfs -L ROOT /dev/mapper/cryptroot
```

## Create and mount BTRFS subvolumes

```bash
BTRFS_OPTS="noatime,compress=zstd,discard=async"
CRYPTROOT=/dev/mapper/cryptroot

# Mount BTRFS root on /mnt
mount -o ${BTRFS_OPTS} ${CRYPTROOT} /mnt

# Create BTRFS subvolumes
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@opt
btrfs su cr /mnt/@root
btrfs su cr /mnt/@srv
btrfs su cr /mnt/@tmp
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@log

umount /mnt

# Mount /mnt using @ BTRFS subvolume
mount -o ${BTRFS_OPTS},subvol=@ ${CRYPTROOT} /mnt

mkdir -pv /mnt/{home,opt,root,srv,tmp,var}
mkdir -pv /mnt/var/{cache,log}

mount -o ${BTRFS_OPTS},subvol=@home ${CRYPTROOT} /mnt/home
mount -o ${BTRFS_OPTS},subvol=@opt ${CRYPTROOT} /mnt/opt
mount -o ${BTRFS_OPTS},subvol=@root ${CRYPTROOT} /mnt/root
mount -o ${BTRFS_OPTS},subvol=@srv ${CRYPTROOT} /mnt/srv
mount -o ${BTRFS_OPTS},subvol=@tmp ${CRYPTROOT} /mnt/tmp
mount -o ${BTRFS_OPTS},subvol=@cache ${CRYPTROOT} /mnt/var/cache
mount -o ${BTRFS_OPTS},subvol=@log ${CRYPTROOT} /mnt/var/log
```

## Create and mount the EFI partition

```bash
mkdir -p /mnt/efi
# Mount /efi
mount -o noatime /dev/vda1 /mnt/efi

# Check that everything looks ok
df -h
```

## Install the base system

Tune the system for optimized download

```bash
nano /etc/pacman.conf
# Set ParallelDownloads to a reasonable number according to your internet connection performance

reflector --country <country> --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

pacstrap -K /mnt base base-devel linux linux-firmware amd-ucode btrfs-progs \
    neovim networkmanager refind git
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


# Edit /etc/local.gen and uncomment your locales
# I use en_US.UTF-8 UTF-8
# Regenerate the locales
locale-gen

# Configure console keymap, timezone and hostname
systemd-firstboot --prompt

# Add user
USER=<your_user_name>
useradd -mg users -G wheel,storage,power -s /bin/bash $USER
passwd $USER
echo "$USER ALL=(ALL) ALL" >> /etc/sudoers.d/$USER 
chmod 0440 /etc/sudoers.d/$USER

# Setup mkinitcpio to handle encryption correctly
# Edit /etc/mkinitcpio.conf and make sure keyboard, keymap (if using non english keyboard layout), consolefont and encrypt hooks are present
# Like HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)

# Generate the initramfs in /boot
mkinitcpio -P

# Install refind bootloader
# This will configure refind in /efi with the btrfs driver
refind-install

# Edit /efi/EFI/refind/refind.conf and configure the extra_kernel_version_string as in arch wiki rEFInd configuration section at https://wiki.archlinux.org/title/REFInd#Configuration
# extra_kernel_version_strings "linux-hardened,linux-rt-lts,linux-zen,linux-lts,linux-rt,linux"

# Next edit /boot/refind_linux.conf because the refind_install script has configured the parameters of the live ISO kernel and not the ones of the chroot environment
# Retrieve the UUID of /dev/mapper/cryptroot and the LUKS device /dev/vda2
ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/cryptroot)
LUKS_UUID=$(blkid -s UUID -o value /dev/sda2)

# It should have the following content
# "Boot using default options"     "root=UUID=$ROOT_UUID cryptdevice=UUID=$LUKS_UUID:root rootflags=subvol=@ rw add_efi_memmap initrd=@\boot\initramfs-%v.img"
# "Boot using fallback initramfs"  "root=UUID=$ROOT_UUID cryptdevice=UUID=$LUKS_UUID:root rootflags=subvol=@ rw add_efi_memmap initrd=@\boot\initramfs-%v-fallback.img"
# "Boot to terminal"               "root=UUID=$ROOT_UUID cryptdevice=UUID=$LUKS_UUID:root rootflags=subvol=@ rw add_efi_memmap initrd=@\boot\initramfs-%v.img systemd.unit=multi-user.target"

# Optional - setup root password
passwd

# Exit chroot and reboot
exit
reboot
```






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




## Snapper snapshots

Create a snapper configuration named root for / path

Install `snap-pac` package to automatically create snapshots when a `pacman` transaction is executed.

Reference: [snap-pac documentation](https://barnettphd.com/snap-pac/index.html)

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
BTRFS_OPTS="noatime,compress=zstd,discard=async"
mount -o ${BTRFS_OPTS},subvol=@ /dev/mapper/cryptroot /mnt
mount -o ${BTRFS_OPTS},subvol=@home ${CRYPTROOT} /mnt/home
mount -o ${BTRFS_OPTS},subvol=@opt ${CRYPTROOT} /mnt/opt
mount -o ${BTRFS_OPTS},subvol=@root ${CRYPTROOT} /mnt/root
mount -o ${BTRFS_OPTS},subvol=@srv ${CRYPTROOT} /mnt/srv
mount -o ${BTRFS_OPTS},subvol=@tmp ${CRYPTROOT} /mnt/tmp
mount -o ${BTRFS_OPTS},subvol=@cache ${CRYPTROOT} /mnt/var/cache
mount -o ${BTRFS_OPTS},subvol=@log ${CRYPTROOT} /mnt/var/log
mount -o noatime /dev/vda1 /mnt/efi
```

Enter in CHROOT and fix the system
