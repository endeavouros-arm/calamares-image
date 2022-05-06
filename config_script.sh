cd /home/alarm/
git clone https://github.com/sravanpannala/enosarm-GUI
rm -rf .config
mkdir .config
mkdir Desktop
cd enosarm-GUI
cp /usr/lib/systemd/system/getty@.service /usr/lib/systemd/system/getty@.service.bak
cp getty@.service /usr/lib/systemd/system/getty@.service
cp clean-up.sh /usr/local/bin/clean-up.sh
chmod +x /usr/local/bin/clean-up.sh
cp clean-up.service /etc/systemd/system/clean-up.service
./alarmconfig.sh
./calamares.sh
chown -R alarm .config Desktop
chmod +x Desktop/Shutdown.sh
printf "[Match]\nName=wlan*\n\n[Network]\nDHCP=yes\nDNSSEC=no\n" > /etc/systemd/network/wlan.network
timedatectl set-ntp true
timedatectl timesync-status
