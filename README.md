
# calamares-image
Files necessary to compile Calamares for Raspberry Pi 4 and Odroid N2 ARM devices
=======

# File Description
## Normal Image Creation
- install-image-linux-aarch64.sh : Create install on uSD
- create-image.sh: Create zstd image to write to uSD
- image-install-calamares.sh: Burn zstd image to uSD
- switch-kernel.sh: Script to run inside arch-chroot
- config_script.sh: Scrip to run inside arch-chroot to add config
## Local Image Creation
This method creates images using local pacman cache
- local-install-image.sh : Create install on uSD
- switch-kernel-local.sh : Has additional functions to use local pacman cache server
## Configs
These are stored in the configs folder

