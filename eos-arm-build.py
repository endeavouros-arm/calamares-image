#!/usr/bin/env python3

import argparse
import subprocess
import os

img_name = "test.img"
img_size = "6G"
img_dir = f"/home/{os.getlogin()}/endeavouros-arm/test-images/"
subprocess.run(["mkdir", "-p", img_dir])


def init_build_script():
    if os.geteuid() != 0:
        exit("Error: Run this script as root")

    if os.path.exists(img_name):
        subprocess.run(["rm", "-rf", img_name])


def parse_function():
    global platform
    global itype
    global create_img
    parser = argparse.ArgumentParser(
        description="Python script to create EndeavourOS ARM images/rootfs"
    )
    parser.add_argument(
        "--platform",
        "-p",
        required=True,
        choices=["rpi", "odn", "pbp"],
        help="Choose platform",
    )
    parser.add_argument(
        "--type",
        "-t",
        choices=["rootfs", "ddimg"],
        default="rootfs",
        help="Choose image type",
    )
    parser.add_argument(
        "--create",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Create image",
    )
    args = parser.parse_args()

    platform = args.platform
    itype = args.type
    create_img = args.create


def partition_device(device: str, boot_partition_start, boot_partition_size):
    boot_partition_size = boot_partition_start + boot_partition_size
    sizest = [boot_partition_start, boot_partition_size]
    sizes = [str(x) + "MiB" for x in sizest]
    create_partition_table = ["mklabel", "msdos"]
    create_boot_partition = ["mkpart", "primary", "fat32", sizes[0], sizes[1]]
    create_root_partition = ["mkpart", "primary", sizes[1], "100%"]
    result = subprocess.run(
        [
            "parted",
            "--script",
            device,
        ]
        + create_partition_table
        + create_boot_partition
        + create_root_partition,
        check=True,
    )


def mount_image(device):
    global arch
    dev1 = device + "p1"
    dev2 = device + "p2"
    mk_boot = ["mkfs.fat", "-n", "BOOT_EOS", dev1]
    mk_root = ["mkfs.ext4", "-F", "-L", "ROOT_EOS", dev2]
    subprocess.run(mk_boot)
    subprocess.run(mk_root)

    subprocess.run(["mkdir", "-p", "MP"])
    subprocess.run(["mount", dev2, "MP"])
    subprocess.run(["mkdir", "-p", "MP/boot"])
    subprocess.run(["mount", dev1, "MP/boot"])
    out = subprocess.run(["uname", "-m"], encoding="utf-8", capture_output=True)
    arch = out.stdout.split("\n")[0]
    if arch == "x86_64":
        subprocess.run(["mkdir", "-p", "MP/usr/bin"])
        subprocess.run(["cp", "/usr/bin/qemu-aarch64-static", "MP/usr/bin"])


def init_image():
    global dev

    subprocess.run(["fallocate", "-l", img_size, img_name])
    subprocess.run(["fallocate", "-d", img_name])
    dev_out = subprocess.run(
        ["losetup", "--find", "--show", img_name], encoding="utf-8", capture_output=True
    )
    dev = dev_out.stdout.split("\n")[0]
    print("Device: " + dev)
    size_out = subprocess.run(
        ["ls", "-al", "--block-size=1M", "test.img"],
        encoding="utf-8",
        capture_output=True,
    )
    # size = size_out.stdout.split()[4]
    # size = str(int(size) - 10)
    # print("Size: " + size)
    boot_start = 16
    boot_size = 256
    partition_device(dev, boot_start, boot_size)
    mount_image(dev)


def copy_chroot():
    chroot_dir = "MP/root/"
    subprocess.run(["cp", "eos-arm-chroot", chroot_dir])
    subprocess.run(["cp", "-r", "configs", chroot_dir])
    files = ["platformname", "type"]
    inputs = [platform, itype]
    for i, (fil, inp) in enumerate(zip(files, inputs)):
        with open(chroot_dir + fil, "w") as f:
            f.write(inp)


def install_image():
    global conf_dir
    conf_dir = os.getcwd() + "/build-configs/"
    fname = conf_dir + f"pkglist-{platform}.txt"
    if arch == "aarch64":
        cmd = ["pacstrap", "-cGM", "MP", "-"]
    elif arch == "x86_64":
        pac_conf = conf_dir + "eos-pacman.conf"
        cmd = ["pacstrap", "-GMC", pac_conf, "MP", "-"]
        mir_dir = "/etc/pacman.d/"
        cmd_m1 = ["ln", "-s", conf_dir + "mirrorlist", mir_dir + "arch-mirrorlist"]
        cmd_m2 = ["ln", "-s", conf_dir + "eos-mirrorlist", mir_dir + "eos-mirrorlist"]
        subprocess.run(cmd_m1)
        subprocess.run(cmd_m2)
    subprocess.run(cmd, stdin=open(fname))

    copy_chroot()
    subprocess.run("genfstab -L MP >> MP/etc/fstab", shell=True)
    if platform == "rpi":
        cmd = """
        old=$(awk \'{print $1}\' MP/boot/cmdline.txt);
        new="root=LABEL=ROOT_EOS";
        boot_options=" usbhid.mousepoll=8";
        sed -i "s#$old#$new#" MP/boot/cmdline.txt;
        sed -i "s/$/$boot_options/" MP/boot/cmdline.txt
        """
        subprocess.run(cmd, shell=True)


def create_rootfs():
    if platform == "pbp":
        img_str = "pbp"
    elif platform == "odn":
        img_str = "odroid-n2"
    if platform == "rpi":
        img_str = "rpi"
    # cmd = f"time bsdtar -cf - * | zstd -z --rsyncable -10 -t0 -of {img_dir}enoslinuxarm-{img_str}-latest.tar.zst"
    # cmd = f"time bsdtar --use-compress-program=zstdmt -cf {img_dir}/enosLinuxARM-odroid-n2-latest.tar.zst *"
    # out = subprocess.run(cmd, shell=True, cwd=os.getcwd() + "/MP")
    cmdp = "time bsdtar -cf - *"
    cmd = [
        "zstd",
        "-z",
        "--sparse",
        "--rsyncable",
        "-10",
        "-T0",
        "-of",
        f"{img_dir}enosLinuxARM-{img_str}-latest.tar.zst",
    ]
    p1 = subprocess.Popen(
        cmdp, shell=True, stdout=subprocess.PIPE, cwd=os.getcwd() + "/MP"
    )
    out = subprocess.run(cmd, stdin=p1.stdout, check=True)
    fname = f"enosLinuxARM-{img_str}-latest.tar.zst"
    cmd = f"sha512sum {fname} > {fname}.sha512sum"
    out = subprocess.run(cmd, shell=True, cwd=img_dir, check=True)


def create_ddimg():
    if platform == "pbp":
        img_str = "pbp"
    elif platform == "odn":
        img_str = "odroid-n2"
    if platform == "rpi":
        img_str = "rpi"

    # cmd = [ "zstd", "-z", "--sparse", "--rsyncable", "-10",
    #         "-T0", "test.img", "-of",
    #         f"{img_dir}enosLinuxARM-{img_str}-latest.img.zst"]
    # fname =f"enosLinuxARM-{img_str}-latest.img.zst"
    cmd = [
        "xz",
        "-cfT0",
        "-1",
        img_name,
    ]
    fname = f"enosLinuxARM-{img_str}-latest.img.xz"
    with open(img_dir + fname, "w") as f:
        out = subprocess.run(cmd, stdout=f, check=True)
    cmd = f"sha512sum {fname} > {fname}.sha512sum"
    out = subprocess.run(cmd, shell=True, cwd=img_dir, check=True)


def finish_up():
    if arch == "x86_64":
        files = [
            "MP/usr/bin/qemu-aarch64-static",
            "/etc/pacman.d/arch-mirrorlist",
            "/etc/pacman.d/eos-mirrorlist",
        ]
        for f in files:
            subprocess.run(["rm", f])
    while True:
        out = subprocess.run(["umount", "MP/boot", "MP"])
        if out.returncode == 0:
            break

    subprocess.run(["rm", "-rf", "MP"])
    subprocess.run(["losetup", "-d", dev])


def main():
    parse_function()
    init_build_script()
    init_image()
    install_image()
    out = subprocess.run(["arch-chroot", "MP", "/root/eos-arm-chroot"], check=True)

    if create_img and itype == "rootfs":
        create_rootfs()

    finish_up()

    if create_img and itype == "ddimg":
        create_ddimg()


if __name__ == "__main__":
    main()
