cd /home/alarm/
rm -rf .config
mkdir .config
mkdir Desktop
cd configs/
# cp /boot/config.txt /boot/config.txt.orig
# cp rpi4-config.txt /boot/config.txt
cp /usr/lib/systemd/system/getty@.service /usr/lib/systemd/system/getty@.service.bak
cp getty@.service /usr/lib/systemd/system/getty@.service
cp clean-up.sh /usr/local/bin/clean-up.sh
chmod +x /usr/local/bin/clean-up.sh
cp clean-up.service /etc/systemd/system/clean-up.service
./alarmconfig.sh
./calamares.sh
cd ..
chown -R alarm .config Desktop .Xauthority
printf "[Match]\nName=wlan*\n\n[Network]\nDHCP=yes\nDNSSEC=no\n" > /etc/systemd/network/wlan.network
timedatectl set-ntp true
timedatectl timesync-status
systemctl enable NetworkManager
