#!/bin/bash

source /usr/share/endeavouros/scripts/eos-script-lib-yad

calamares-official() {
    sudo cp /home/alarm/configs/calamares/settings_online.conf /etc/calamares/settings.conf
    sudo -E calamares -D 8 >> /home/alarm/endeavour-install.log
}
export -f calamares-official

calamares-community() {
    sudo cp /home/alarm/configs/calamares/settings_community.conf /etc/calamares/settings.conf
    sudo -E calamares -D 8 >> /home/alarm/endeavour-install.log
}
export -f calamares-community

edit-mirrors() {
    xfce4-terminal -e "sudo nano /etc/pacman.d/mirrorlist"
}
export -f edit-mirrors


yad --title "EndeavourOS ARM Installer" --form --width=500 --height=200 --image=endeavouros --window-icon=endeavouros --button=yad-cancel:1 \
 --text="<b>EndeavourOS ARM Installer:</b> 
 Please ensure that you are connected to the internet before proceeding to the Calamares installer. 
 Network connection options are available in the system tray on the bottom right of your screen." \
--field="<b>Install Official Editions</b>":fbtn "bash -c calamares-official" \
--field="<b>Install Community Editions</b>":fbtn "bash -c calamares-community" \
--field="<b>Edit Mirrorlist</b>":fbtn "bash -c edit-mirrors"
