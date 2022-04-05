#!/bin/bash

# get CPU Vendor
cpuv = lscpu | grep "Vendor ID" | awk '{ print $3}'

drive=/dev/sda
EFI=/dev/sda1
part=/dev/sda2
mountpoint=/mnt/
stick=/mnt/usb/

echo
echo "Creating Network"
echo
dhclient
ping -c 5 archlinux.org

# partition the disk
echo
echo "partitioning the drive"
echo
parted -a optimal --script $drive -- \
mklabel gpt  \
   unit mib \
   mkpart primary fat32 1 50M  \
   name 1 EFI \
   set 1 esp on \
   mkpart primary btrfs 50M -1 \
   name 2 ROOTFS \
   print

sleep 1
echo "make filesystems"
echo
mkfs.vfat -F 32 -n EFI $EFI
mkfs.btrfs -f -L "btrfs_pool" ${part}

echo
echo "making btrfs mountpoints"
echo
mount ${drive}2 ${mountpoint}
btrfs sub create ${mountpoint}/@
btrfs sub create ${mountpoint}/@home
btrfs sub create ${mountpoint}/@pkg
btrfs sub create ${mountpoint}/@log
btrfs sub create ${mountpoint}/@snapshots

umount ${mountpoint}

echo
echo "mounting btrfs volumes"

mount -o rw,noatime,compress=zstd,subvol=@ ${part} ${mountpoint}

[[ -d ${mountpoint}/boot/efi ]] || mkdir -p ${mountpoint}/boot/efi
[[ -d ${mountpoint}/home ]] || mkdir -p ${mountpoint}/home
[[ -d ${mountpoint}/snapshots ]] || mkdir -p ${mountpoint}/.snapshots
[[ -d ${mountpoint}/arch/var ]] || mkdir -p ${mountpoint}/var/cache/pacman/pkg
[[ -d ${mountpoint}/arch/var ]] || mkdir -p ${mountpoint}/var/log

mount -o rw,noatime,compress=zstd,subvol=@home ${part} ${mountpoint}/home
mount -o rw,noatime,compress=zstd,subvol=@snapshots ${part} ${mountpoint}/.snapshots
mount -o rw,noatime,compress=zstd,subvol=@pkg ${part} ${mountpoint}/var/cache/pacman/pkg
mount -o rw,noatime,compress=zstd,subvol=@log ${part} ${mountpoint}/var/log

echo
echo "copying and unpacking stage3"
echo
pacstrap ${mountpoint} base linux linux-firmware btrfs-progs vim base-devel amd-ucode bash-completion man-pages git

echo "Mounting boot partitions\n"
mount ${drive}1 ${mountpoint}/boot/efi
genfstab -U ${mountpoint} >> ${mountpoint}/etc/fstab
cat ${mountpoint}/etc/fstab
read -p "Press enter to continue"

echo "change rooting into the system\n"
arch-chroot ${mountpoint} 
exit
