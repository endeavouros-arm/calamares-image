#!/bin/bash

_check_if_root() {
    if [ $(id -u) -ne 0 ]
    then
      printf "\n\n${RED}PLEASE RUN THIS SCRIPT AS ROOT OR WITH SUDO${NC}\n\n"
      exit
    fi
}   # end of function _check_if_root

_check_internet_connection() {
    printf "\n${CYAN}Checking Internet Connection...${NC}\n\n"
    ping -c 3 endeavouros.com -W 5
    if [ "$?" != "0" ]
    then
       printf "\n\n${RED}No Internet Connection was detected\nFix your Internet Connectin and try again${NC}\n\n"
       exit
    fi
}   # end of function _check_internet_connection

_find_mirrorlist() {
    # find and install current endevouros-arm-mirrorlist
    local tmpfile
    local currentmirrorlist
    local ARMARCH="aarch64"

    printf "\n${CYAN}Find current endeavouros-mirrorlist...${NC}\n\n"
    sleep 1
    curl https://github.com/endeavouros-team/repo/tree/master/endeavouros/$ARMARCH | grep "endeavouros-mirrorlist" |sed s'/^.*endeavouros-mirrorlist/endeavouros-mirrorlist/'g | sed s'/pkg.tar.zst.*/pkg.tar.zst/'g |tail -1 > mirrors

    tmpfile="mirrors"
    read -d $'\x04' currentmirrorlist < "$tmpfile"

    printf "\n${CYAN}Downloading endeavouros-mirrorlist...${NC}"
    wget https://github.com/endeavouros-team/repo/raw/master/endeavouros/$ARMARCH/$currentmirrorlist 2>> /root/enosARM.log

    printf "\n${CYAN}Installing endeavouros-mirrorlist...${NC}\n"
    pacman -U --noconfirm $currentmirrorlist &>> /root/enosARM.log

    printf "\n[endeavouros]\nSigLevel = PackageRequired\nInclude = /etc/pacman.d/endeavouros-mirrorlist\n\n" >> /etc/pacman.conf

    rm mirrors
}  # end of function _find_mirrorlist


_find_keyring() {
    local tmpfile
    local currentkeyring
    local ARMARCH="aarch64"

    printf "\n${CYAN}Find current endeavouros-keyring...${NC}\n\n"
    sleep 1
    curl https://github.com/endeavouros-team/repo/tree/master/endeavouros/$ARMARCH |grep endeavouros-keyring |sed s'/^.*endeavouros-keyring/endeavouros-keyring/'g | sed s'/pkg.tar.zst.*/pkg.tar.zst/'g | tail -1 > keys

    tmpfile="keys"
    read -d $'\04' currentkeyring < "$tmpfile"

    printf "\n${CYAN}Downloading endeavouros-keyring...${NC}"
    wget https://github.com/endeavouros-team/repo/raw/master/endeavouros/$ARMARCH/$currentkeyring 2>> /root/enosARM.log

    printf "\n${CYAN}Installing endeavouros-keyring...${NC}\n"
    pacman -U --noconfirm $currentkeyring &>> /root/enosARM.log

    rm keys
}   # End of function _find_keyring

_base_addons() {
    ### the following installs all packages needed to match the EndeavourOS base install
    printf "\n${CYAN}Installing EndeavourOS Base Addons...${NC}\n"
    eos-packagelist --arch arm "Systembase + Common packages" "Firefox and language package" > base-addons
    printf "openbox\npcmanfm-gtk3\ntint2\nnetwork-manager-applet\nxfce4-terminal\n" >> base-addons
    pacman -S --noconfirm --needed - < base-addons
    ### Install Calamares Arm
    wget https://github.com/pudges-place/exper/releases/download/v0.2/calamares_current-22.04.1.4-1-any.pkg.tar.xz
    pacman -U --noconfirm calamares_current-22.04.1.4-1-any.pkg.tar.xz
    wget https://github.com/pudges-place/exper/releases/download/v0.2/calamares_config_default-22.04.1.4-1-any.pkg.tar.xz
    pacman -U --noconfirm calamares_config_default-22.04.1.4-1-any.pkg.tar.xz
    wget https://github.com/pudges-place/exper/releases/download/v0.2/calamares_config_ce-22.04.1.4-1-any.pkg.tar.xz
    pacman -U --noconfirm calamares_config_ce-22.04.1.4-1-any.pkg.tar.xz
    rm -rf calamares_config_default-22.04.1.4-1-any.pkg.tar.xz calamares_current-22.04.1.4-1-any.pkg.tar.xz calamares_config_ce-22.04.1.4-1-any.pkg.tar.xz base-addons
}


_finish_up() {
    printf "alarm ALL=(ALL:ALL) NOPASSWD: ALL\n" >> /etc/sudoers
    gpasswd -a alarm wheel
    printf "exec openbox-session\n" >> /home/alarm/.xinitrc
    printf "if [ -z \"\${DISPLAY}\" ] && [ \"\${XDG_VTNR}\" -eq 1 ]; then\n  exec startx\nfi\n" >> /home/alarm/.bash_profile
    chown alarm:alarm /home/alarm/.xinitrc
    chmod 644 /home/alarm/.xinitrc
    rm -rf /endeavouros*
    systemctl disable dhcpcd.service
    systemctl enable NetworkManager.service
    sed -i 's/ParallelDownloads = 8/#ParallelDownloads = 5/g' /etc/pacman.conf
    pacman -Rn --noconfirm dhcpcd
    printf "\nalias ll='ls -l --color=auto'\n" >> /etc/bash.bashrc
    printf "alias la='ls -al --color=auto'\n" >> /etc/bash.bashrc
    printf "alias lb='lsblk -o NAME,FSTYPE,FSSIZE,LABEL,MOUNTPOINT'\n\n" >> /etc/bash.bashrc
    rm /var/cache/pacman/pkg/*
    rm /root/switch-kernel.sh /root/enosARM.log   
    rm -rf /etc/pacman.d/gnupg
    rm -rf /etc/lsb-release
    printf "\n\n${CYAN}Your uSD is ready for creating an image.${NC}\n"
    # read -n 1 z
    # systemctl poweroff
}   # end of function _finish_up

######################   Start of Script   #################################
Main() {

   # Declare color variables
      GREEN='\033[0;32m'
      RED='\033[0;31m'
      CYAN='\033[0;36m'
      NC='\033[0m' # No Color

   # STARTS HERE
   dmesg -n 1 # prevent low level kernel messages from appearing during the script
   _check_if_root
   _check_internet_connection
   sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 8/g' /etc/pacman.conf
   pacman-key --init
   pacman-key --populate archlinuxarm
   pacman -Syy
   pacman -R --noconfirm linux-aarch64 uboot-raspberrypi
   pacman -Syu --noconfirm --needed linux-rpi raspberrypi-bootloader raspberrypi-firmware git libnewt wget networkmanager base-devel
   _find_mirrorlist
   _find_keyring
   pacman -Syy
   pacman -S --noconfirm --needed eos-packagelist
   _base_addons
   _finish_up
}  # end of Main

Main "$@"
