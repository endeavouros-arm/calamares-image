#!/bin/bash

_check_if_root() {
    local whiptail_installed

    if [ $(id -u) -ne 0 ]
    then
       whiptail_installed=$(pacman -Qs libnewt)
       if [[ "$whiptail_installed" != "" ]]; then
          whiptail --title "Error - Cannot Continue" --msgbox "Please run this script with sudo or as root" 8 47
          exit
       else
          printf "${RED}Error - Cannot Continue. Please run this script with sudo or as root.${NC}\n"
          exit
       fi
    fi
    if [[ "$SUDO_USER" == "" ]]; then
        USERNAME=$USER
    else
        USERNAME=$SUDO_USER  
    fi
}   # end of function _check_if_root

_choose_device() {

   local base_dialog_content
   local dialog_content
   local finished
   local exit_status

   base_dialog_content="\nThe following storage devices were found\n\n$(lsblk -o NAME,MODEL,FSTYPE,SIZE,FSUSED,FSAVAIL,MOUNTPOINT)\n\n \
   Enter source device name without a partition designation (e.g. /dev/sda or /dev/mmcblk0):"
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
}   # end of function _choose_device

_unmount_partitions() {
    local count
    local i
    local u
    local x

    lsblk $DEVICENAME -o MOUNTPOINT | grep /run/media > mounts
    count=$(wc -l mounts | awk '{print $1}')
    if [[ "$count" -gt "0" ]]
    then
       for ((i = 1 ; i <= $count ; i++))
       do
          u=$(awk -v "x=$i" 'NR==x' mounts)
          umount $u
       done
       printf "\nSource Partitions unmounted\n"
    fi
    rm mounts
}   # end of function _umount_partitions

##################### Start of Scipt #################

DEVICENAME=" "
USERNAME=" "

_check_if_root
_choose_device
mkdir MP1
mkdir MP1/boot
if [[ ${DEVICENAME:5:6} = "mmcblk" ]]
then
   DEVICENAME=$DEVICENAME"p"
fi
   
PARTNAME1=$DEVICENAME"1"
PARTNAME2=$DEVICENAME"2"
_unmount_partitions

mount $PARTNAME2 MP1
mount $PARTNAME1 MP1/boot

   # read in platformname passed by install-image-aarch64.sh to /mnt/root
   file="MP1/root/platformname"
   read -d $'\x04' PLATFORM_NAME < "$file"
   echo $PLATFORM_NAME
   rm MP1/root/platformname
cd MP1

printf "\nbsdtar is creating the image, may take a few minutes\n"

case $PLATFORM_NAME in
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
umount MP1/boot MP1
rm -rf MP1



