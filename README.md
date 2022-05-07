# exper
RPi 4b experimental scripts and images

# File Description
## Normal Image Creation
- install-image-linux-aarch64.sh : Create install on uSD
- create-image.sh: Create zstd image to write to uSD
- image-install-calamares.sh: Burn zstd image to uSD
## Image Creation Without Config
- install-image-linux-aarch64-V2.sh: Create install on uSD without config
- create-image-V2.sh: Create zstd image without config
- image-install-calamares-V2.sh: Script to burn zstd image with config
## Common for both
- switch-kernel.sh: Script to run inside arch-chroot
- config_script.sh: Scrip to run inside arch-chroot to add config
## Configs
These are stored in the configs folder
