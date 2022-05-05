#!/bin/bash

userdel -r alarm
sed -i 's/alarm ALL=(ALL:ALL) NOPASSWD: ALL/ /g' /etc/sudoers
pacman -Rns --noconfirm calamares_current-22.04.1.4-1-any.pkg.tar.xz calamares_config_default-22.04.1.4-1-any.pkg.tar.xz
rm -rf /etc/calamares/settings.conf
cp -f /usr/lib/systemd/system/getty@.service.bak /usr/lib/systemd/system/getty@.service
rm -rf /usr/lib/systemd/system/getty@.service.break
rm /usr/local/bin/user-install.sh
rm /etc/systemd/system/user-install.service
# systemctl reboot

exit


