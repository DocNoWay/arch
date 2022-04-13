#!/bin/bash

loadkeys de-latin1

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

sed -i '/de_DE.UTF/s/^#//' /etc/locale.gen
sed -i '/en_US.UTF-8/s/^#//' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" > /etc/vconsole.conf
echo "archie" > /etc/hostname

# create a user
useradd -m -G wheel,video -s /bin/bash -c "Andreas Finck" andreas
echo andreas:password | chpasswd
# enable root login for group wheel user
cat /etc/sudoers | sed -i 's/# %wheel/%wheel/g' /etc/sudoers

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

pacman -S ntp grub grub-btrfs efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-headers avahi gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups alsa-utils pulseaudio pavucontrol bash-completion openssh rsync reflector acpi acpi_call virt-viewer qemu-arch-extra openbsd-netcat ipset firewalld nss-mdns acpid ntfs-3g terminus-font man-db man-pages wget curl

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable firewalld

echo root:password | chpasswd

# link vi to vim 
echo "#Some usefull aliases" >> /etc/bash.bashrc
echo "alias vi='vim'" >> /etc/bash.bashrc
echo "alias ls='ls --color' >> /etc/bash.bashrc
echo "alias ll='ls -l'" >> /etc/bash.bashrc
echo "alias la='ls -a'" >> /etc/bash.bashrc
echo "" >> /etc/bash.bashrc
echo "export EDITOR='vim'" >> /etc/bash.bashrc

echo "set number" >>  /etc/vimrc
echo "set relativenumber" >> /etc/vimrc
echt "syntax on" >>  /etc/vimrc
echo "colorscheme elflord" >>  /etc/vimrc

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck --removable
grub-mkconfig -o /boot/grub/grub.cfg

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m\n"
