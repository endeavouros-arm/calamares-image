#!/bin/bash
yad --title "EndeavourOS ARM Installer" --form --width=500 --height=200 --text="<b>EndeavourOS ARM Installer:</b> 
Please ensure that you are connected to the internet before proceeding to the Calamares installer. 
Network connection options are available in the system tray on the bottom right of your screen." \
 --image "/usr/share/endeavouros/EndeavourOS-icon.png" --image-on-top \
--field="<b>Calamares Installer</b>":fbtn "sudo -E calamares" \
--button=cancel:1

