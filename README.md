
# calamares-image
Files necessary to compile Calamares for Raspberry Pi 4 and Odroid N2 ARM devices
=======
Run
```
sudo ./build-image-eos.sh -h
```
to get help on how to build the image.


# File Description
## Current method
- build-image-eos.sh : Script to build eos-arm images
- build-image-chroot.sh : Chroot script run by the above script

## Experimental method
- img-build-eos.sh : Script to build eos-arm images using `loop` module
- img-chroot-eos.sh : Chroot script run by the above script

## Configs
These are stored in the configs folder

# Older Methods
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


