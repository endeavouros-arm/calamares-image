#!/bin/bash

calamares-official() {
   local logfile="$1"
   sudo cp /home/alarm/configs/calamares/settings_online.conf /etc/calamares/settings.conf
   pkexec calamares -c /etc/calamares -d >> $logfile
}
export -f calamares-official

calamares-community() {
   local logfile="$1"
   sudo cp /home/alarm/configs/calamares/settings_community.conf /etc/calamares/settings.conf
   pkexec calamares -c /etc/calamares -d >> $logfile
}
export -f calamares-community

yad --title "EndeavourOS ARM Installer" --form --width=500 --height=200 --image=endeavouros --window-icon=endeavouros --button=yad-cancel:1 \
 --text="<b>EndeavourOS ARM Installer:</b> 
 Please ensure that you are connected to the internet before proceeding to the Calamares installer. 
 Network connection options are available in the system tray on the bottom right of your screen." \
 --field="<b>Install Official Editions</b>":fbtn "calamares-official /home/alarm/endeavour-install.log" \
 --field="<b>Install Community Editions</b>":fbtn "calamares-community /home/alarm/endeavour-install.log" 

