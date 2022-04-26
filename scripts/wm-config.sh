#!/bin/bash
country=Germany
kbmap=de
#output=Virtual-1
output=DP-1
resolution=2560x1440
# Options
run_reflector=true      # configures the reflector archlinux mirror chooser
aur_helper=true         # Install YAY or not
install_lightdm=false   # Install lightdm or not
gen_xprofile=false      # Generate a xprofile for xorg
windowmanager=sway      # options are: sway(wayland) i3(xorg) dwm(xorg)

sudo timedatectl set-ntp true
sudo hwclock --systohc

inst_ldm() {
    sudo pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
    sudo systemctl enable lightdm
}

set-xprofile() {
    cat > ~/.xprofile << EOF
    setxkbmap $kbmap
    nitrogen --restore
    xrandr --output $output --mode $resolution
EOF
}

if [[ $run_reflector = true ]]; then
    sudo reflector -c $country -a 12 --sort rate --save /etc/pacman.d/mirrorlist
fi
if [[ $install_lightdm = true ]]; then
    inst_ldm
fi
if [[ $aur_helper = true ]]; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay/;makepkg -si --noconfirm;cd
fi
if [[ $get_xprofile = true ]]; then
    set-xprofile
fi

sudo pacman -S --noconfirm dina-font tamsyn-font ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-cascadia-code ttf-fantasque-sans-mono ttf-fira-mono ttf-hack ttf-fira-code ttf-inconsolata ttf-jetbrains-mono ttf-monofur adobe-source-code-pro-fonts cantarell-fonts inter-font ttf-opensans gentium-plus-font ttf-junicode adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-cjk noto-fonts-emoji python-requests pacman-contrib playerctl pavucontrol archlinux-wallpaper awesome-terminal-fonts ttf-font-awesome

get-dwm() {
    # Pull Git repositories and install
    cd /tmp
    repos=( "dmenu" "dwm" "dwmstatus" "st" "slock" )
    for repo in ${repos[@]}
    do
        git clone git://git.suckless.org/$repo
        cd $repo;make;sudo make install;cd ..
    done

    # XSessions and dwm.desktop
    if [[ ! -d /usr/share/xsessions ]]; then
        sudo mkdir /usr/share/xsessions
    fi

    cat > ./temp << "EOF"
    [Desktop Entry]
    Encoding=UTF-8
    Name=Dwm
    Comment=Dynamic window manager
    Exec=dwm
    Icon=dwm
    Type=XSession
EOF
    sudo cp ./temp /usr/share/xsessions/dwm.desktop;rm ./temp
}

swaypkg="sway swaybg waybar foot kitty swayidle swaylock qutebrowser wofi pcmanfm xorg-xwayland polkit-gnome lxappearance playerctl pavucontrol xorg-xhost"
i3pkg="i3 xorg firefox polkit-gnome nitrogen lxappearance arandr terminator picom dmenu rofi pcmanfm python-requests gnome-system-monitor pacman-contrib playerctl pavucontrol python-dbus dunst"

case $windowmanager in
sway)
    sudo pacman -S --noconfirm $swaypkg;;
i3)
    sudo pacman -S --noconfirm $i3pkg;;
dwm)
    sudo pacman -S --noconfirm xorg qutebrowser pcmanfm ;
    inst_ldm ;
    get-dwm ;
   set-xprofile ;;
esac

printf "\e[1;32mDone! you can now reboot.\e[0m\n"
