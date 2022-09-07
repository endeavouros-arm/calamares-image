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
    pacstrap -cGM MP - < pkglist-pbp.txt
    _copy_stuff_for_chroot
    rm -rf MP/etc/fstab
    printf "/dev/mmcblk1p1  /boot   vfat    defaults        0       0\n/dev/mmcblk1p2  /   ext4   defaults     0    0\n" >> MP/etc/fstab
}   # End of function _install_Pinebook_image

_install_OdroidN2_image() {
    pacstrap -cGM MP - < pkglist-odn.txt
    _copy_stuff_for_chroot
}   # End of function _install_OdroidN2_image


_install_RPi4_image() { 
    pacstrap -cGM MP - < pkglist-rpi.txt
    _copy_stuff_for_chroot
    # sed -i 's/mmcblk0/mmcblk1/' MP/etc/fstab
    genfstab -L MP2 >> MP2/etc/fstab
    old=$(awk '{print $1}' MP2/boot/cmdline.txt)
    new="root=ROOT_EOS"
    boot_options=" usbhid.mousepoll=8"
    sed -i "s#$old#$new#" MP2/boot/cmdline.txt
    sed -i "s/$/$boot_options/" MP2/boot/cmdline.txt
}  # End of function _install_RPi4_image

_partition_format_mount() {
   # truncate -s 6G test.img
   fallocate -l 7.5G test.img
   fallocate -d test.img
   # dd if=/dev/zero of=./test.img bs=4MiB count=1500 conv=sparse,sync,noerror
   # dd conv=sparse bs=1MiB count=6000 if=/dev/zero of=./test.img
   losetup --find --show test.img
   DEVICENAME="/dev/loop0"
   ##### Determine data device size in MiB and partition ###
   printf "\n${CYAN}Partitioning, & formatting storage device...${NC}\n"
   DEVICESIZE=$(fdisk -l | grep "Disk $DEVICENAME" | awk '{print $5}')
   ((DEVICESIZE=$DEVICESIZE/1048576))
   ((DEVICESIZE=$DEVICESIZE-10))  # for some reason, necessary for USB thumb drives
   printf "\n${CYAN}Partitioning storage device $DEVICENAME...${NC}\n"
   printf "\ndevicename = $DEVICENAME     devicesize = $DEVICESIZE\n" >> /root/enosARM.log
   # umount partitions before partitioning and formatting
   case $PLATFORM in   
      RPi64)    _partition_RPi4 ;;
      OdroidN2) _partition_OdroidN2 ;;
      Pinebook) _partition_Pinebook ;;
   esac
  
   printf "\npartition name = $DEVICENAME\n\n" >> /root/enosARM.log
   printf "\n${CYAN}Formatting storage device $DEVICENAME...${NC}\n"
   printf "\n${CYAN}If \"/dev/sdx contains a ext4 file system Labelled XXXX\" or similar appears, Enter: y${NC}\n\n\n"

   DEVICENAME1=$DEVICENAME"p"
   
   PARTNAME1=$DEVICENAME1"1"
   mkfs.fat -n BOOT_EOS $PARTNAME1   2>> /root/enosARM.log
   PARTNAME2=$DEVICENAME1"2"
   mkfs.ext4 -F -L ROOT_EOS $PARTNAME2   2>> /root/enosARM.log
   # mkdir MP1 MP
   mkdir MP
   mount $PARTNAME2 MP
   mkdir MP/boot
   mount $PARTNAME1 MP/boot

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

_copy_stuff_for_chroot() {
    cp img-chroot-eos.sh MP/root/
    cp config_script.sh MP/root/
    mkdir -p MP/root/
    cp -r configs/ MP/root/
    printf "$PLATFORM\n" > platformname
    printf "$LOCAL\n" > mirrors
    cp platformname MP/root/
    cp mirrors MP/root/
    rm platformname
    rm mirrors
}

_arch_chroot(){
    arch-chroot MP /root/img-chroot-eos.sh
    # arch-chroot MP /root/config_script.sh
}

_create_image(){
    case $PLATFORM in
       OdroidN2)# time bsdtar --use-compress-program=zstdmt -cf /home/$USERNAME/endeavouros-arm/images/enosLinuxARM-odroid-n2-latest.tar.zst *
          time bsdtar -cf - * | zstd -z --rsyncable -10 -T0 -of /home/$USERNAME/endeavouros-arm/images/enosLinuxARM-odroid-n2-latest.tar.zst
          printf "\n\nbsdtar is finished creating the image.\nand will calculate a sha512sum\n\n"
          cd ..
          dir=$(pwd)
          cd /home/$USERNAME/endeavouros-arm/images/
          sha512sum enosLinuxARM-odroid-n2-latest.tar.zst > enosLinuxARM-odroid-n2-latest.tar.zst.sha512sum
          cd $dir ;;
       Pinebook)# time bsdtar --use-compress-program=zstdmt -cf /home/$USERNAME/endeavouros-arm/images/enosLinuxARM-pbp-latest.tar.zst *
          time bsdtar -cf - * | zstd -z --rsyncable -10 -T0 -of /home/$USERNAME/endeavouros-arm/images/enosLinuxARM-pbp-latest.tar.zst
          printf "\n\nbsdtar is finished creating the image.\nand will calculate a sha512sum\n\n"
          cd ..
          dir=$(pwd)
          cd /home/$USERNAME/endeavouros-arm/images/
          sha512sum enosLinuxARM-pbp-latest.tar.zst > enosLinuxARM-pbp-latest.tar.zst.sha512sum
          cd $dir ;;
       RPi64) # time bsdtar --use-compress-program=zstdmt -cf /home/$USERNAME/endeavouros-arm/images/enosLinuxARM-rpi-aarch64-latest.tar.zst *
          time bsdtar -cf - * | zstd -z --rsyncable -10 -T0 -of /home/$USERNAME/endeavouros-arm/images/enosLinuxARM-rpi-aarch64-latest.tar.zst
          printf "\n\nbsdtar is finished creating the image.\nand will calculate a sha512sum\n\n"
          cd ..
          dir=$(pwd)
          cd /home/$USERNAME/endeavouros-arm/images/
          sha512sum enosLinuxARM-rpi-aarch64-latest.tar.zst > enosLinuxARM-rpi-aarch64-latest.tar.zst.sha512sum
          cd $dir ;;
    esac
}

_help() {
   # Display Help
   printf "\nHELP\n"
   printf "Build EndeavourOS ARM Images\n"
   printf "options:\n"
   printf " -h  Print this Help.\n\n"
   printf "All these options are required\n"
   printf " -p  enter platform: rpi or odn or pbp\n"
   printf " -c  create image: y or n\n"
   printf " -l  use local pacman mirrors: y or n\n"
   printf "example: sudo ./build-image-eos -p rpi -c y -m l\n\n"
}

_read_options() {
    # Available options
    opt=":p:c:l:h:"
    local OPTIND

    if [[ ! $@ =~ ^\-.+ ]]
    then
      echo "The script requires an argument, aborting"
      _help
      exit 1
    fi

    while getopts "${opt}" arg; do
      case $arg in
        p)
          PLAT="${OPTARG}"
          ;;
        c)
          CRE="${OPTARG}"
          ;;
        l)
          LOC="${OPTARG}"
          ;;
        \?)
          echo "Option -${OPTARG} is not valid, aborting"
          _help
          exit 1
          ;;
        h|?)
          _help
          exit 1
          ;;
        :)
          echo "Option -${OPTARG} requires an argument, aborting"
          _help
          exit 1
          ;;
      esac
    done
    shift $((OPTIND-1))

case $PLAT in
     rpi) PLATFORM="RPi64" ;;
     odn) PLATFORM="OdroidN2" ;;
     pbp) PLATFORM="Pinebook" ;;
       *) PLAT1=true;;
esac

case $DOWN in
     y) DOWNLOAD=true ;;
     n) DOWNLOAD=false ;;
     *) DOWNLOAD=true ;;
esac

case $CRE in
     y) CREATE=true ;;
     n) CREATE=false ;;
     *) CREATE=true ;;
esac

case $LOC in
     y) LOCAL=true ;;
     n) LOCAL=false ;;
     *) LOCAL=false ;;
esac


}

#################################################
# beginning of script
#################################################

Main() {
    # VARIABLES
    PLAT=""
    PLATFORM=" "     # e.g. OdroidN2, RPi4b, etc.
    DEVICENAME=" "   # storage device name e.g. /dev/sda
    DEVICESIZE="1"
    PARTNAME1=" "
    PARTNAME2=" "
    USERNAME=" "
    DOWN=" "
    DOWNLOAD=" "
    CREATE=" "
    LOC=" "
    LOCAL=" "
    
    # Declare color variables
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color

    pacman -S --noconfirm --needed libnewt arch-install-scripts time &>/dev/null # for whiplash dialog
    _check_if_root
    _read_options "$@"

    rm -rf test.img
    _partition_format_mount  # function to partition, format, and mount a uSD card or eMMC card
    case $PLATFORM in
       RPi64)    _install_RPi4_image ;;
       OdroidN2) _install_OdroidN2_image ;;
       Pinebook) _install_Pinebook_image ;;
    esac

    printf "\n\n${CYAN}arch-chroot to switch kernel.${NC}\n\n"
    _arch_chroot

    case $PLATFORM in
       OdroidN2)
          dd if=MP/boot/u-boot.bin of=$DEVICENAME conv=fsync,notrunc bs=512 seek=1
          ;;
       Pinebook)
           sed -i "s|root=LABEL=ROOT_ALARM|root=/dev/mmcblk1p2|g" MP/boot/extlinux/extlinux.conf
           # u-boot
           # dd if=MP/boot/idbloader.img of=$DEVICENAME seek=64 conv=notrunc,fsync
           # dd if=MP/boot/u-boot.itb of=$DEVICENAME seek=16384 conv=notrunc,fsync
           # Tow-Boot
           dd if=MP/boot/Tow-Boot.noenv.bin of=$DEVICENAME seek=64 conv=notrunc,fsync
           ;;
    esac

    if $CREATE ; then
        printf "\n\n${CYAN}Creating Image${NC}\n\n"
        cd MP
        _create_image
        printf "\n\n${CYAN}Created Image${NC}\n\n"
    fi

    umount MP/boot MP
    rm -rf MP

    losetup -d /dev/loop0
    # rm ArchLinuxARM*

    exit
}

Main "$@"
