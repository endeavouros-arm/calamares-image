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
    if $DOWNLOAD ; then
        # wget https://github.com/SvenKiljan/archlinuxarm-pbp/releases/latest/download/ArchLinuxARM-pbp-latest.tar.gz
        wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
    fi
    printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
    # bsdtar -xpf ArchLinuxARM-pbp-latest.tar.gz -C MP2
    bsdtar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C MP2
    # mv MP2/boot/* MP1
    _copy_stuff_for_chroot
    rm -rf MP2/etc/fstab
    printf "/dev/mmcblk1p1  /boot   vfat    defaults        0       0\n/dev/mmcblk1p2  /   ext4   defaults     0    0\n" >> MP2/etc/fstab
}   # End of function _install_Pinebook_image

_install_OdroidN2_image() {
    local user_confirm
    if $DOWNLOAD ; then
        wget http://os.archlinuxarm.org/os/ArchLinuxARM-odroid-n2-latest.tar.gz
    fi
    printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
    bsdtar -xpf ArchLinuxARM-odroid-n2-latest.tar.gz -C MP2
    # mv MP2/boot/* MP1
    dd if=MP2/boot/u-boot.bin of=$DEVICENAME conv=fsync,notrunc bs=512 seek=1
    _copy_stuff_for_chroot
}   # End of function _install_OdroidN2_image


_install_RPi4_image() { 
    local failed=""   
    if $DOWNLOAD ; then
        wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
    fi
    printf "\n\n${CYAN}Untarring the image...may take a few minutes.${NC}\n"
    bsdtar -xpf ArchLinuxARM-rpi-aarch64-latest.tar.gz -C MP2
    printf "\n\n${CYAN}syncing files...may take a few minutes.${NC}\n"
    sync
    # mv MP2/boot/* MP1
    _copy_stuff_for_chroot
    sed -i 's/mmcblk0/mmcblk1/' MP2/etc/fstab
}  # End of function _install_RPi4_image

_partition_format_mount() {
   local count
   local i
   local u
   local x

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

_copy_stuff_for_chroot() {
    cp build-image-chroot.sh MP2/root/
    cp config_script.sh MP2/root/
    cp -r configs/ MP2/home/alarm/
    printf "$PLATFORM\n" > platformname
    printf "$LOCAL\n" > mirrors
    cp platformname MP2/root/
    cp mirrors MP2/root/
    rm platformname
    rm mirrors
}

_arch_chroot(){
    arch-chroot MP2 /root/build-image-chroot.sh
    # arch-chroot MP2 /root/config_script.sh
}

_create_image(){
    case $PLATFORM in
       OdroidN2)# time bsdtar --use-compress-program=zstdmt -cf /home/$USERNAME/endeavouros-arm/test-images/enosLinuxARM-odroid-n2-latest.tar.zst *
          time bsdtar -cf - * | zstd -z --rsyncable -10 -T0 -of /home/$USERNAME/endeavouros-arm/test-images/enosLinuxARM-odroid-n2-latest.tar.zst
          printf "\n\nbsdtar is finished creating the image.\nand will calculate a sha512sum\n\n"
          cd ..
          dir=$(pwd)
          cd /home/$USERNAME/endeavouros-arm/test-images/
          sha512sum enosLinuxARM-odroid-n2-latest.tar.zst > enosLinuxARM-odroid-n2-latest.tar.zst.sha512sum
          cd $dir ;;
       Pinebook)# time bsdtar --use-compress-program=zstdmt -cf /home/$USERNAME/endeavouros-arm/test-images/enosLinuxARM-pbp-latest.tar.zst *
          time bsdtar -cf - * | zstd -z --rsyncable -10 -T0 -of /home/$USERNAME/endeavouros-arm/test-images/enosLinuxARM-pbp-latest.tar.zst
          printf "\n\nbsdtar is finished creating the image.\nand will calculate a sha512sum\n\n"
          cd ..
          dir=$(pwd)
          cd /home/$USERNAME/endeavouros-arm/test-images/
          sha512sum enosLinuxARM-pbp-latest.tar.zst > enosLinuxARM-pbp-latest.tar.zst.sha512sum
          cd $dir ;;
       RPi64) # time bsdtar --use-compress-program=zstdmt -cf /home/$USERNAME/endeavouros-arm/test-images/enosLinuxARM-rpi-aarch64-latest.tar.zst *
          time bsdtar -cf - * | zstd -z --rsyncable -10 -T0 -of /home/$USERNAME/endeavouros-arm/test-images/enosLinuxARM-rpi-latest.tar.zst
          printf "\n\nbsdtar is finished creating the image.\nand will calculate a sha512sum\n\n"
          cd ..
          dir=$(pwd)
          cd /home/$USERNAME/endeavouros-arm/test-images/
          sha512sum enosLinuxARM-rpi-latest.tar.zst > enosLinuxARM-rpi-latest.tar.zst.sha512sum
          cd $dir ;;
    esac
}

_help() {
   # Display Help
   printf "\nHELP\n"
   printf "Build EndeavourOS ARM Images\n"
   printf "options:\n"
   printf " -h  Print this Help.\n\n"
   printf "These options are required\n"
   printf " -d  enter device name for ex: sda\n"
   printf " -p  enter platform: rpi or odn or pbp\n"
   printf "These options are optional\n"
   printf " -i  download base image: (y) or n\n"
   printf " -c  create image: (y) or n\n"
   printf " -l  use local pacman mirrors: y or (n)\n"
   printf "example: sudo ./build-image-eos -d sda -p rpi -i y -c y -l n\nl"
   printf "Ensure that the directory /home/\$username/endeaouros-arm/test-images exists\n\n"
}

_read_options() {
    # Available options
    opt=":d:p:i:c:l:h:"
    local OPTIND

    if [[ ! $@ =~ ^\-.+ ]]
    then
      echo "The script requires an argument, aborting"
      _help
      exit 1
    fi

    while getopts "${opt}" arg; do
      case $arg in
        d)
          DEVICENAME="/dev/${OPTARG}"
          ;;
        p)
          PLAT="${OPTARG}"
          ;;
        i)
          DOWN="${OPTARG}"
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
    DEVICETYPE=" "
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
           sed -i "s|root=LABEL=ROOT_ALARM|root=/dev/mmcblk1p2|g" MP2/boot/extlinux/extlinux.conf
           # u-boot
           # dd if=MP2/boot/idbloader.img of=$DEVICENAME seek=64 conv=notrunc,fsync
           # dd if=MP2/boot/u-boot.itb of=$DEVICENAME seek=16384 conv=notrunc,fsync
           # Tow-Boot
           dd if=MP2/boot/Tow-Boot.noenv.bin of=$DEVICENAME seek=64 conv=notrunc,fsync
           ;;
    esac

    if $CREATE ; then
        printf "\n\n${CYAN}Creating Image${NC}\n\n"
        cd MP2
        _create_image
        printf "\n\n${CYAN}Created Image${NC}\n\n"
    fi

    umount MP2/boot MP2
    rm -rf MP2
    # rm ArchLinuxARM*

    exit
}

Main "$@"
