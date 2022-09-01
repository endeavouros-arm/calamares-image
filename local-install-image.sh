#!/bin/bash

_partition_Pinebook() {
    dd if=/dev/zero of=$DEVICENAME bs=1M count=16
    parted --script -a minimal $DEVICENAME \
    mklabel msdos \
    unit mib \
    mkpart primary fat32 16MiB 216MiB \
    mkpart primary 216MiB $DEVICESIZE"MiB" \
    quit
}

_partition_OdroidN2() {
    parted --script -a minimal $DEVICENAME \
    mklabel msdos \
    unit mib \
    mkpart primary fat32 2MiB 258MiB \
    mkpart primary 258MiB $DEVICESIZE"MiB" \
    quit
}

_partition_RPi4() {
    parted --script -a minimal $DEVICENAME \
    mklabel gpt \
    unit MiB \
    mkpart primary fat32 2MiB 202MiB \
    mkpart primary ext4 202MiB $DEVICESIZE"MiB" \
    quit
}

_install_Pinebook_image() {
    local user_confirm
    # wget https://github.com/SvenKiljan/archlinuxarm-pbp/releases/latest/download/ArchLinuxARM-pbp-latest.tar.gz
    # wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
    printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
    # bsdtar -xpf ArchLinuxARM-pbp-latest.tar.gz -C MP2
    bsdtar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C MP2
    # mv MP2/boot/* MP1
    _copy_stuff_for_chroot
    # for Odroid N2 ask if storage device is micro SD or eMMC or USB device
    user_confirm=$(whiptail --title " Odroid N2 / N2+" --menu --notags "\n             Choose Storage Device or Press right arrow twice to abort" 17 100 3 \
         "0" "micro SD card" \
         "1" "eMMC card" \
         "2" "USB device" \
    3>&2 2>&1 1>&3)

    case $user_confirm in
       "") printf "\nScript aborted by user\n\n"
           exit ;;
        0) rm -rf MP2/etc/fstab
           DEVICETYPE="uSD"
           printf "/dev/mmcblk1p1  /boot   vfat    defaults        0       0\n/dev/mmcblk1p2  /   ext4   defaults     0    0\n" >> MP2/etc/fstab ;;
        1) rm -rf MP2/etc/fstab
           DEVICETYPE="eMMC"
           printf "/dev/mmcblk2p1  /boot   vfat    defaults        0       0\n/dev/mmcblk2p2  /   ext4   defaults     0    0\n" >> MP2/etc/fstab ;;
        # 1) printf "\nN2 micro SD card\n" > /dev/null ;;
        2) DEVICETYPE="USB"
           printf "\nN2 micro SD card\n" > /dev/null ;;
    esac
#    cp $CONFIG_UPDATE MP2/root
}   # End of function _install_Pinebook_image

_install_OdroidN2_image() {
    local user_confirm

    # wget http://os.archlinuxarm.org/os/ArchLinuxARM-odroid-n2-latest.tar.gz
    printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
    bsdtar -xpf ArchLinuxARM-odroid-n2-latest.tar.gz -C MP2
    # mv MP2/boot/* MP1
    dd if=MP2/boot/u-boot.bin of=$DEVICENAME conv=fsync,notrunc bs=512 seek=1
    _copy_stuff_for_chroot
    # for Odroid N2 ask if storage device is micro SD or eMMC or USB device
    user_confirm=$(whiptail --title " Odroid N2 / N2+" --menu --notags "\n             Choose Storage Device or Press right arrow twice to abort" 17 100 3 \
         "0" "micro SD card" \
         "1" "eMMC card" \
         "2" "USB device" \
    3>&2 2>&1 1>&3)

    case $user_confirm in
       "") printf "\nScript aborted by user\n\n"
           exit ;;
        0) printf "\nN2 micro SD card\n" > /dev/null ;;
        1) sed -i 's/mmcblk1/mmcblk0/g' MP2/etc/fstab ;;
        2) sed -i 's/root=\/dev\/mmcblk${devno}p2/root=\/dev\/sda2/g' MP1/boot.ini
           printf "\# Static information about the filesystems.\n# See fstab(5) for details.\n\n# <file system> <dir> <type> <options> <dump> <pass>\n" > MP2/etc/fstab
           printf "/dev/sda1  /boot   vfat    defaults        0       0\n/dev/sda2  /   ext4   defaults     0    0\n" >> MP2/etc/fstab ;;
    esac
#    cp $CONFIG_UPDATE MP2/root
}   # End of function _install_OdroidN2_image

_install_RPi4_image() { 
    local failed=""   

    # wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
    printf "\n\n${CYAN}Untarring the image...may take a few minutes.${NC}\n"
    bsdtar -xpf ArchLinuxARM-rpi-aarch64-latest.tar.gz -C MP2
    printf "\n\n${CYAN}syncing files...may take a few minutes.${NC}\n"
    sync
    # mv MP2/boot/* MP1
    _copy_stuff_for_chroot
    failed=$?
    if [[ "$failed" != "0" ]]; then
        printf "\n\n${CYAN}The switch-kernel.sh script failed to be copied to /root.${NC}\n"
    else
        printf "\n\n${CYAN}The switch-kernel.sh script was copied to /root.${NC}\n"
    fi
    sed -i 's/mmcblk0/mmcblk1/' MP2/etc/fstab
}  # End of function _install_RPi4_image

_partition_format_mount() {
   local finished
   local base_dialog_content
   local dialog_content
   local exit_status
   local count
   local i
   local u
   local x

   base_dialog_content="\nThe following storage devices were found\n\n$(lsblk -o NAME,MODEL,FSTYPE,SIZE,FSUSED,FSAVAIL,MOUNTPOINT)\n\n \
   Enter target device name without a partition designation (e.g. /dev/sda or /dev/mmcblk0):"
   dialog_content="$base_dialog_content"
   finished=1
   while [ $finished -ne 0 ]
   do
       DEVICENAME=$(whiptail --title "EndeavourOS ARM Setup - micro SD Configuration" --inputbox "$dialog_content" 27 115 3>&2 2>&1 1>&3)
      exit_status=$?
      if [[ "$exit_status" == "1" ]]; then           
         printf "\nScript aborted by user\n\n"
         exit
      fi
      if [[ ! -b "$DEVICENAME" ]]; then
         dialog_content="$base_dialog_content\n    Not a listed block device, or not prefaced by /dev/ Try again."
      else   
         case $DEVICENAME in
            /dev/sd*)     if [[ ${#DEVICENAME} -eq 8 ]]; then
                             finished=0
                          else
                             dialog_content="$base_dialog_content\n    Input improperly formatted. Try again."   
                          fi ;;
            /dev/mmcblk*) if [[ ${#DEVICENAME} -eq 12 ]]; then
                             finished=0
                          else
                             dialog_content="$base_dialog_content\n    Input improperly formatted. Try again."   
                          fi ;;
         esac
      fi      
   done
   ##### Determine data device size in MiB and partition ###
   printf "\n${CYAN}Partitioning, & formatting storage device...${NC}\n"
   DEVICESIZE=$(fdisk -l | grep "Disk $DEVICENAME" | awk '{print $5}')
   ((DEVICESIZE=$DEVICESIZE/1048576))
   ((DEVICESIZE=$DEVICESIZE-1))  # for some reason, necessary for USB thumb drives
   printf "\n${CYAN}Partitioning storage device $DEVICENAME...${NC}\n"
   printf "\ndevicename = $DEVICENAME     devicesize = $DEVICESIZE\n" >> /root/enosARM.log
   # umount partitions before partitioning and formatting
   lsblk $DEVICENAME -o MOUNTPOINT | grep /run/media > mounts
   count=$(wc -l mounts | awk '{print $1}')
   if [[ "$count" -gt "0" ]]
   then
      for ((i = 1 ; i <= $count ; i++))
      do
         u=$(awk -v "x=$i" 'NR==x' mounts)
         umount $u
      done
   fi
   rm mounts
   case $PLATFORM in   
      RPi64)    _partition_RPi4 ;;
      OdroidN2) _partition_OdroidN2 ;;
      Pinebook) _partition_Pinebook ;;
   esac
  
   printf "\npartition name = $DEVICENAME\n\n" >> /root/enosARM.log
   printf "\n${CYAN}Formatting storage device $DEVICENAME...${NC}\n"
   printf "\n${CYAN}If \"/dev/sdx contains a ext4 file system Labelled XXXX\" or similar appears, Enter: y${NC}\n\n\n"

   if [[ ${DEVICENAME:5:6} = "mmcblk" ]]
   then
      DEVICENAME=$DEVICENAME"p"
   fi
   
   PARTNAME1=$DEVICENAME"1"
   mkfs.fat $PARTNAME1   2>> /root/enosARM.log
   PARTNAME2=$DEVICENAME"2"
   mkfs.ext4 -F $PARTNAME2   2>> /root/enosARM.log
   # mkdir MP1 MP2
   mkdir MP2
   mount $PARTNAME2 MP2
   mkdir MP2/boot
   mount $PARTNAME1 MP2/boot

} # end of function _partition_format_mount

_check_if_root() {
    local whiptail_installed

    if [ $(id -u) -ne 0 ]
    then
       whiptail_installed=$(pacman -Qs libnewt)
       if [[ "$whiptail_installed" != "" ]]; then
          whiptail --title "Error - Cannot Continue" --msgbox "  Please run this script as sudo or root" 8 47
          exit
       else
          printf "${RED}Error - Cannot Continue. Please run this script as sudo or root.${NC}\n"
          exit
       fi
    fi
    if [[ "$SUDO_USER" == "" ]]; then     
         USERNAME=$USER
    else
         USERNAME=$SUDO_USER  
    fi
}  # end of function _check_if_root

_check_all_apps_closed() {
    whiptail --title "CAUTION" --msgbox "Ensure ALL apps are closed, especially any file manager such as Thunar" 8 74 3>&2 2>&1 1>&3
}

_copy_stuff_for_chroot() {
    cp switch-kernel-local.sh MP2/root/
    cp config_script.sh MP2/root/
    cp -r configs/ MP2/home/alarm/
    printf "$PLATFORM\n" > platformname
    cp platformname MP2/root/
    rm platformname
}

_arch_chroot(){
    arch-chroot MP2 /root/switch-kernel-local.sh
    arch-chroot MP2 /root/config_script.sh
}

_choose_device() {
    PLATFORM=$(whiptail --title " SBC Model Selection" --menu --notags "\n            Choose which SBC to install or Press right arrow twice to cancel" 17 100 4 \
         "0" "Raspberry Pi 4b 64 bit" \
         "1" "Odroid N2 or N2+" \
         "2" "Pinebook Pro" \
    3>&2 2>&1 1>&3)

    case $PLATFORM in
        "") printf "\n\nScript aborted by user..${NC}\n\n"
            exit ;;
         0) PLATFORM="RPi64" ;;
         1) PLATFORM="OdroidN2" ;;
         2) PLATFORM="Pinebook" ;;
    esac
}

#################################################
# beginning of script
#################################################

Main() {
    # VARIABLES
    PLATFORM=" "     # e.g. OdroidN2, RPi4b, etc.
    DEVICENAME=" "   # storage device name e.g. /dev/sda
    DEVICESIZE="1"
    PARTNAME1=" "
    PARTNAME2=" "
    USERNAME=" "
    DEVICETYPE=" "

    # Declare color variables
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color

    pacman -S --noconfirm --needed libnewt arch-install-scripts time &>/dev/null # for whiplash dialog
    _check_if_root
    _check_all_apps_closed
    _choose_device

    _partition_format_mount  # function to partition, format, and mount a uSD card or eMMC card
    case $PLATFORM in
       RPi64)    _install_RPi4_image ;;
       OdroidN2) _install_OdroidN2_image ;;
       Pinebook) _install_Pinebook_image ;;
    esac

    printf "\n\n${CYAN}arch-chroot to switch kernel.${NC}\n\n"
    _arch_chroot

    case $PLATFORM in
       Pinebook)
           case $DEVICETYPE in
               # uSD) sed -i "s|root=LABEL=ROOT_MNJRO|root=/dev/mmcblk1p2|g" MP2/boot/extlinux/extlinux.conf ;;
               # eMMC) sed -i "s|root=LABEL=ROOT_MNJRO|root=/dev/mmcblk2p2|g" MP2/boot/extlinux/extlinux.conf ;;
               uSD) sed -i "s|root=LABEL=ROOT_ALARM|root=/dev/mmcblk1p2|g" MP2/boot/extlinux/extlinux.conf ;;
               eMMC) sed -i "s|root=LABEL=ROOT_ALARM|root=/dev/mmcblk2p2|g" MP2/boot/extlinux/extlinux.conf ;;
           esac
           # u-boot
           # dd if=MP2/boot/idbloader.img of=$DEVICENAME seek=64 conv=notrunc,fsync
           # dd if=MP2/boot/u-boot.itb of=$DEVICENAME seek=16384 conv=notrunc,fsync
           # Tow-Boot
           dd if=MP2/boot/Tow-Boot.noenv.bin of=$DEVICENAME seek=64 conv=notrunc,fsync ;;
    esac

    umount MP2/boot MP2
    rm -rf MP2
    # rm ArchLinuxARM*

    printf "\n\n${CYAN}End of script!${NC}\n"
    printf "\n${CYAN}Be sure to use a file manager to umount the device before removing the USB SD reader${NC}\n"

    printf "\n${CYAN}The default user is ${NC}alarm${CYAN} with the password ${NC}alarm\n"
    printf "${CYAN}The default root password is ${NC}root\n\n\n"

    exit
}

Main "$@"
