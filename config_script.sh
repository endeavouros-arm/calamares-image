cd /home/alarm/
# su - alarm
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
cp /boot/config.txt /boot/config.txt.orig
cp rpi4-config.txt /boot/config.txt 
chown -R alarm .config Desktop
chmod +x Desktop/Shutdown.sh
