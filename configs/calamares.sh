cd calamares
sudo cp -f $(pwd)/settings.conf  /etc/calamares/
sudo cp -f $(pwd)/netinstall.yaml /etc/calamares/modules/
sudo cp -f $(pwd)/packagechooser.conf /etc/calamares/modules/
sudo cp -f $(pwd)/shellprocess_initialize_pacman.conf /etc/calamares/modules/
sudo cp -f $(pwd)/create-pacman-keyring /etc/calamares/scripts/
sudo cp -f $(pwd)/cleaner_script.sh /etc/calamares/scripts/
sudo cp -f $(pwd)/eos_script_cleaner.conf /etc/calamares/modules/
cd ..
