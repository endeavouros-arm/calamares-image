#!/bin/bash

package=xfce4-session
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3
fi

package=i3-gaps
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3
fi

package=plasma-desktop
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3 xfce4-terminal
fi

package=gnome-shell
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3 xfce4-terminal
fi

package=mate-desktop
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3 xfce4-terminal
fi

package=cinnamon-desktop
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3 xfce4-terminal
fi

package=budgie-desktop
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3 xfce4-terminal
fi

package=lxqt-session
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm tint2 pcmanfm-gtk3 xfce4-terminal
fi

package=lxde-common
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm tint2 xfce4-terminal
fi

package=bspwm
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3
fi

package=qtile
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3
fi

package=sway
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox tint2 pcmanfm-gtk3 xfce4-terminal
fi

package=worm
if pacman -Qq $package > /dev/null ; then
  pacman -Rns --noconfirm openbox pcmanfm-gtk3
fi

userdel -r alarm
sed -i 's/alarm ALL=(ALL:ALL) NOPASSWD: ALL/ /g' /etc/sudoers
pacman -Rns --noconfirm calamares_current_arm calamares_config_default_arm calamares_config_ce_arm
rm -rf /etc/calamares/
rm /usr/local/bin/clean-up.sh
rm /etc/systemd/system/clean-up.service

exit
