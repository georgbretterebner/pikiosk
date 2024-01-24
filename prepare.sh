#!/bin/bash

# To get the newest download link for cef please visit and copy
#   the link from: Current Stable Build - Sample Application
#
# https://cef-builds.spotifycdn.com/index.html#linuxarm64
#
# For debian please go to and copy the desired Link
# https://raspi.debian.net/daily-images/

CEF_DL_LINK="https://cef-builds.spotifycdn.com/cef_binary_120.2.7%2Bg4bc6a59%2Bchromium-120.0.6099.234_linuxarm64_client.tar.bz2"
DEBIAN_DL_LINK="https://raspi.debian.net/daily/raspi_3_bookworm.img.xz"


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

./conf.sh

wget -O - $DEBIAN_DL_LINK | unxz > debian.img

dd if=/dev/zero bs=1M count=2000 >> debian.img
LOOP_DEVICE=$(losetup -fP --show debian.img)
parted "$LOOP_DEVICE" resizepart 2 4G
resize2fs "${LOOP_DEVICE}p2"
mkdir image
mount "${LOOP_DEVICE}p2" ./image

mkdir ./image/kiosksetup
cp -r ./install/* ./image/kiosksetup

rm -rf ./cef-bin
mkdir cef-bin
wget -O - $CEF_DL_LINK |
tar -xj --strip-components=2 -C cef-bin
mkdir ./image/kiosksetup/cef-bin
mv cef-bin ./image/kiosksetup
mv ./20-wireless.network ./image/etc/systemd/network
cp ./firstboot.service ./image/lib/systemd/system
ln -s ./image/lib/systemd/system/firstboot.service ./image/etc/systemd/system/multi-user.target.wants/firstboot.service

sync
umount ./image
rmdir ./image

mkdir boot
mount "${LOOP_DEVICE}p1" ./boot
cp ./firstboot.sh ./boot

sync
umount ./boot
rmdir ./boot

losetup -d "$LOOP_DEVICE"

printf "\n\n"

echo "Available hard drives:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
echo "Enter the name of the hard drive to flash the image to."
echo "Enter it in the form of \"sdXX\" or \"mmcblkXX\" etc.."
read -p ":" selected_drive
if [ -z "$selected_drive" ]; then
    echo "Invalid input. Exiting script."
    exit
fi
echo "You have chosen to flash to '/dev/$selected_drive'."
read -p "Do you want to proceed? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "Operation canceled. Exiting."
    exit 1
fi
echo "Flashing the image. Please wait..."
dd if="./debian.img" of="/dev/$selected_drive" bs=4M status=progress

eject /dev/$selected_drive

echo "You can now remove the SD-Card"