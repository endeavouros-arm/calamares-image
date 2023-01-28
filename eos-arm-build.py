#!/usr/bin/env python3

import argparse
import subprocess
from subprocess import Popen
import os
import time
from subprocess import run as run_unsafe


def run(*args, **kwargs):
    out = run_unsafe(*args, **(kwargs | {'check': True}))
    return out


img_name = "test.img"
img_size = "6G"
try:
    img_dir = f"/home/{os.getlogin()}/endeavouros-arm/test-images/"
except:
    img_dir = "/root/test-images/"
run(["mkdir", "-p", img_dir])

CRED = "\033[41m"
CEND = "\033[0m"


def init_build_script():
    if os.geteuid() != 0:
        exit("Error: Run this script as root")

    if os.path.exists(img_name):
        run(["rm", "-rf", img_name])


def parse_function():
    global platform
    global itype
    global create_img
    parser = argparse.ArgumentParser(
        description="Python script to create EndeavourOS ARM images/rootfs",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
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
    result = run(
        [
            "parted",
            "--script",
            device,
        ]
        + create_partition_table
        + create_boot_partition
        + create_root_partition,
        encoding="utf-8",
        capture_output=True,
    )
    print(result.stdout)
    run(["partprobe", device])
    # run(f"partprobe {device}",shell=True)


def mount_image(device):
    global arch
    dev1 = device + "p1"
    dev2 = device + "p2"
    mk_boot = ["mkfs.fat", "-n", "BOOT_EOS", dev1]
    mk_root = ["mkfs.ext4", "-F", "-L", "ROOT_EOS", dev2]
    out = run(mk_boot, encoding="utf-8", capture_output=True)
    print(out.stdout)
    out = run(mk_root, encoding="utf-8", capture_output=True)
    print(out.stdout)

    run(["mkdir", "-p", "MP"])
    run(["mount", dev2, "MP"])
    run(["mkdir", "-p", "MP/boot"])
    run(["mount", dev1, "MP/boot"])
    out = run(["uname", "-m"], encoding="utf-8", capture_output=True)
    arch = out.stdout.split("\n")[0]
    if arch == "x86_64":
        run(["mkdir", "-p", "MP/usr/bin"])
        run(["cp", "/usr/bin/qemu-aarch64-static", "MP/usr/bin"])


def init_image():
    global dev

    run(["fallocate", "-l", img_size, img_name])
    run(["fallocate", "-d", img_name])
    dev_out = run(
        ["losetup", "--find", "--show", "--partscan", img_name], encoding="utf-8", capture_output=True
    )
    dev = dev_out.stdout.split("\n")[0]
    print("Device: " + dev)
    size_out = run(
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
    run(["cp", "eos-arm-chroot", chroot_dir])
    run(["cp", "-r", "configs", chroot_dir])
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
        cmd_m1 = ["ln", "-s", conf_dir +
                  "mirrorlist", mir_dir + "arch-mirrorlist"]
        cmd_m2 = ["ln", "-s", conf_dir +
                  "eos-mirrorlist", mir_dir + "eos-mirrorlist"]
        run(cmd_m1)
        run(cmd_m2)
    run(cmd, stdin=open(fname), stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)

    print(CRED + "fstab" + CEND)
    copy_chroot()
    run("genfstab -L MP >> MP/etc/fstab", shell=True)
    cmd = """
    sed -i 's/subvolid=.*,//g' MP/etc/fstab
    sed -i /swap/d MP/etc/fstab
    sed -i /zram/d MP/etc/fstab
    """
    print(CRED + "Shell Commands" + CEND)
    run(cmd, shell=True)
    if platform == "rpi" and itype == "ddimg":
        cmd = """
        old=$(awk \'{print $1}\' MP/boot/cmdline.txt);
        echo $old
        new="root=LABEL=ROOT_EOS";
        echo $new
        boot_options=" usbhid.mousepoll=8";
        sed -i "s#$old#$new#" MP/boot/cmdline.txt;
        sed -i "s/$/$boot_options/" MP/boot/cmdline.txt
        """
        run(cmd, shell=True)
    elif platform == "odn" and itype == "ddimg":
        cmd = """
        old=$(grep 'setenv bootargs \"root=' MP/boot/boot.ini);
        echo $old
        new='setenv bootargs \"root=LABEL=ROOT_EOS rootwait rw\"';
        echo $new
        sed -i "s#$old#$new#" MP/boot/boot.ini;
        """
        run(cmd, shell=True)
    elif platform == "pbp" and itype == "ddimg":
        cmd = """
        old=$(grep -o 'root=.* ' MP/boot/extlinux/extlinux.conf);
        echo $old
        new="root=LABEL=ROOT_EOS rw rootwait";
        echo $new
        sed -i "s#$old#$new#" MP/boot/extlinux/extlinux.conf;
        """
        run(cmd, shell=True)
    print(CRED + "End of Pacstrap" + CEND)


def create_rootfs():
    if platform == "pbp":
        img_str = "pbp"
    elif platform == "odn":
        img_str = "odroid-n2"
    if platform == "rpi":
        img_str = "rpi"
    # cmd = f"time bsdtar -cf - * | zstd -z --rsyncable -10 -t0 -of {img_dir}enoslinuxarm-{img_str}-latest.tar.zst"
    # cmd = f"time bsdtar --use-compress-program=zstdmt -cf {img_dir}/enosLinuxARM-odroid-n2-latest.tar.zst *"
    # out = run(cmd, shell=True, cwd=os.getcwd() + "/MP")
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
    print(CRED + "Creating tar compatible image" + CEND)
    p1 = Popen(cmdp, shell=True, stdout=subprocess.PIPE,
               cwd=os.getcwd() + "/MP")
    run(cmd, stdin=p1.stdout)
    fname = f"enosLinuxARM-{img_str}-latest.tar.zst"
    cmd = f"sha512sum {fname} > {fname}.sha512sum"
    run(cmd, shell=True, cwd=img_dir)


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
    print(CRED + "Creating dd compatible image" + CEND)
    with open(img_dir + fname, "w") as f:
        run(cmd, stdout=f)
    cmd = f"sha512sum {fname} > {fname}.sha512sum"
    run(cmd, shell=True, cwd=img_dir)


def finish_up():
    if arch == "x86_64":
        files = [
            "MP/usr/bin/qemu-aarch64-static",
            "/etc/pacman.d/arch-mirrorlist",
            "/etc/pacman.d/eos-mirrorlist",
        ]
        for f in files:
            run(["rm", f])
    # while True:
    #     out = run(["umount", "MP/boot"])
    #     print(out)
    #     if out.returncode == 0:
    #         break
    # while True:
    #     out = run(["umount", "MP"])
    #     print(out)
    #     if out.returncode == 0:
    #         break

    run(["umount", "MP/boot"])
    run(["umount", "MP"])
    run(["rm", "-rf", "MP"])
    run(["losetup", "-d", dev])


def main():
    start_time = time.time()
    parse_function()
    init_build_script()
    init_image()
    install_image()
    print(CRED + "Arch Chroot" + CEND)
    run(["arch-chroot", "MP", "/root/eos-arm-chroot"])
    build_time = time.time()
    if create_img and itype == "rootfs":
        create_rootfs()

    finish_up()

    if create_img and itype == "ddimg":
        create_ddimg()
    create_time = time.time()
    build_t = build_time - start_time
    create_t = create_time - build_time
    total_t = create_time - start_time
    print(f"Build Time : {build_t//60:04.1f}m{build_t%60:04.1f}s")
    print(f"Create Time: {create_t//60:04.1f}m{create_t%60:04.1f}s")
    print(f"Total Time : {total_t//60:04.1f}m{total_t%60:04.1f}s")
    print(CRED + "End of image build" + CEND)


if __name__ == "__main__":
    main()
