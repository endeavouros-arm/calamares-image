cd calamares
cp -f $(pwd)/settings.conf  /etc/calamares/
cp -f $(pwd)/netinstall.yaml /etc/calamares/modules/
cp -f $(pwd)/packagechooser.conf /etc/calamares/modules/
cp -f $(pwd)/shellprocess_initialize_pacman.conf /etc/calamares/modules/
cp -f $(pwd)/create-pacman-keyring /etc/calamares/scripts/
cp -f $(pwd)/cleaner_script.sh /etc/calamares/scripts/
cp -f $(pwd)/shellprocess_script_cleaner.conf /etc/calamares/modules/
cd ..
