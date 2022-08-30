#!/bin/bash

## Function to remove calamares openbox environment packages
_remove_packages_ob () {
  local OPENBOX=true
  local TINT=true
  local XFCETERM=true
  local PCMANFM=true
  
  if pacman -Qq xfce4-session > /dev/null ; then
    XFCETERM=false
  elif pacman -Qq i3-gaps > /dev/null ; then
    XFCETERM=false
  elif pacman -Qq plasma-desktop > /dev/null ; then
    true
  elif pacman -Qq gnome-shell > /dev/null ; then
    true
  elif pacman -Qq mate-desktop > /dev/null ; then
    true
  elif pacman -Qq cinnamon-desktop > /dev/null ; then
    true
  elif pacman -Qq budgie-desktop > /dev/null ; then
    true
  elif pacman -Qq lxqt-session > /dev/null ; then
    OPENBOX=false
  elif pacman -Qq lxde-common > /dev/null ; then
    OPENBOX=false
    PCMANFM=false
  elif pacman -Qq bspwm > /dev/null ; then
    XFCETERM=false
  elif pacman -Qq qtile > /dev/null ; then
    XFCETERM=false
  elif pacman -Qq sway > /dev/null ; then
    true
  elif pacman -Qq worm > /dev/null ; then
    XFCETERM=false
    TINT=false
  else
    OPENBOX=false
    XFCETERM=false
    TINT=false
  fi
  
  if $OPENBOX ; then
    pacman -Rns --noconfirm openbox
  fi

  if $XFCETERM ; then
    pacman -Rns --noconfirm xfce4-terminal
  fi

  if $TINT ; then
    pacman -Rns --noconfirm tint2
  fi

  if $PCMANFM ; then
    pacman -Rns --noconfirm pcmanfm-gtk3
  fi
}

Main() {
  sed -i 's/alarm ALL=(ALL:ALL) NOPASSWD: ALL/ /g' /etc/sudoers
  cp /home/alarm/endeavour-install.log /var/log/
  userdel -rf alarm
  _remove_packages_ob
  pacman -Rns --noconfirm calamares_current_arm calamares_config_default_arm calamares_config_ce_arm
  pacman -Rns flameshot
  rm -rf /etc/calamares/
  rm /usr/local/bin/clean-up.sh
  rm /etc/systemd/system/clean-up.service
  exit
}

Main "$@"
