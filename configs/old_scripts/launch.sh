#!/bin/bash

yad --title "EndeavourOS ARM Installer" --form --width=500 --height=200 --image=endeavouros --window-icon=endeavouros --button=yad-cancel:1 \
 --text="<b>EndeavourOS ARM Installer:</b> 
 Please ensure that you are connected to the internet before proceeding to the Calamares installer. 
 Network connection options are available in the system tray on the bottom right of your screen." \
--field="<b>Install Official Editions</b>":fbtn "/home/alarm/cal_online.sh" \
--field="<b>Install Community Editions</b>":fbtn "/home/alarm/cal_ce.sh"
