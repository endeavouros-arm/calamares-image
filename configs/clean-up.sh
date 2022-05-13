#!/bin/bash

package=xfce4
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm
fi

package=i3-gaps
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm
fi

package=plasma-dekstop
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm xfce4-terminal
fi

package=gnome-shell
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm xfce4-terminal
fi

package=mate
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm xfce4-terminal
fi

package=budgie-dekstop
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm xfce4-terminal
fi

package=lxqt
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm tint2 pcmanfm xfce4-terminal
fi

package=lxde-common
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm tint2 xfce4-terminal
fi

package=bspwm
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm
fi

package=qtile
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm
fi

package=sway
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm xfce4-terminal
fi

package=worm
if pacman -Qs $package > /dev/null ; then
  pacman -Rns --noconfirm tint2 pcmanfm
fi

userdel -r alarm
sed -i 's/alarm ALL=(ALL:ALL) NOPASSWD: ALL/ /g' /etc/sudoers
pacman -Rns --noconfirm calamares_current_arm calamares_config_default_arm calamares_config_ce_arm
rm -rf /etc/calamares/
rm /usr/local/bin/clean-up.sh
rm /etc/systemd/system/clean-up.service

exit
