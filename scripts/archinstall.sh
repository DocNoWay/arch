#!/bin/bash
dhclient
ping -c 5 archlinux.org
read -p "Last change to abort. If you press enter installation starts and your hdd will be formated."

drive=/dev/sda
EFI=${drive}1
part=${drive}2
mountpoint=/mnt/
stick=/mnt/usb/

parted -a optimal --script $drive -- \
mklabel gpt  \
   unit mib \
   mkpart primary fat32 1 50M  \
   name 1 EFI \
   set 1 esp on \
   mkpart primary btrfs 50M -1 \
   name 2 ROOTFS \
   print

mkfs.vfat -F 32 -n EFI $EFI
mkfs.btrfs -f -L "btrfs_pool" ${part}

mount ${part} ${mountpoint}
btrfs sub create ${mountpoint}/@
btrfs sub create ${mountpoint}/@home
btrfs sub create ${mountpoint}/@pkg
btrfs sub create ${mountpoint}/@log
btrfs sub create ${mountpoint}/@snapshots
umount ${mountpoint}

mount -o rw,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@ ${part} ${mountpoint}

[[ -d ${mountpoint}/boot/efi ]] || mkdir -p ${mountpoint}/boot/efi
[[ -d ${mountpoint}/home ]] || mkdir -p ${mountpoint}/home
[[ -d ${mountpoint}/snapshots ]] || mkdir -p ${mountpoint}/.snapshots
[[ -d ${mountpoint}/arch/var ]] || mkdir -p ${mountpoint}/var/cache/pacman/pkg
[[ -d ${mountpoint}/arch/var ]] || mkdir -p ${mountpoint}/var/log

mount -o rw,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@home ${part} ${mountpoint}/home
mount -o rw,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@snapshots ${part} ${mountpoint}/.snapshots
mount -o rw,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@pkg ${part} ${mountpoint}/var/cache/pacman/pkg
mount -o rw,noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@log ${part} ${mountpoint}/var/log

pacstrap ${mountpoint} base linux linux-firmware btrfs-progs vim intel-ucode bash-completion man-pages man-db git sudo

mount ${EFI} ${mountpoint}/boot/efi

genfstab -U ${mountpoint} >> ${mountpoint}/etc/fstab
cat ${mountpoint}/etc/fstab
read -p "Press enter to continue"

arch-chroot ${mountpoint}
