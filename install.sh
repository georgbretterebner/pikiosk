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

dd if=/dev/zero bs=10M count=200 >> debian.img
LOOP_DEVICE=$(losetup -fP --show debian.img)
parted "$LOOP_DEVICE" resizepart 2 4G
resize2fs "${LOOP_DEVICE}p2"

mkdir image
mount "${LOOP_DEVICE}p2" ./image

rm -rf ./cef-bin
mkdir cef-bin
wget -O - $CEF_DL_LINK |
tar -xj --strip-components=2 -C cef-bin

mkdir ./image/kiosksetup
mkdir ./image/kiosksetup/cef-bin
mv cef-bin ./image/kiosksetup
cp -r ./files/* ./image/kiosksetup
chown -R root ./image/kiosksetup


mv ./25-wlan.network ./image/etc/systemd/network
mv ./resolv.conf ./image/etc

rm -f ./image/etc/systemd/system/network-online.target.wants/networking.service
rm -f ./image/etc/systemd/system/multi-user.target.wants/networking.service

mv ./image/etc/network/interfaces ./image/etc/network/interfaces.save
mv ./image/etc/network/interfaces.d ./image/etc/network/interfaces.d.save

ln -s ./image/usr/lib/systemd/system/systemd-networkd.service ./image/etc/systemd/system/network-online.target.wants
ln -s ./image/usr/lib/systemd/system/systemd-networkd.service ./image/etc/systemd/system/multi-user.target.wants


mv ./wpa_supplicant-wlan0.conf ./image/etc/wpa_supplicant
ln -s ./image/lib/systemd/system/wpa_supplicant@.service ./image/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service

cp ./files/firstboot.service ./image/lib/systemd/system
ln -s ./image/lib/systemd/system/firstboot.service ./image/etc/systemd/system/multi-user.target.wants/firstboot.service

mv ./files/firstboot.sh ./image/kiosksetup
chmod +x ./image/kiosksetup/firstboot.sh

mv ./kiosk.service ./image/etc/systemd/system
rm -f ./image/etc/systemd/system/getty.target.wants/*

mv ./westonkiosk.sh ./image/kiosksetup
chmod +x ./image/kiosksetup/westonkiosk.sh

sync
umount ./image
rmdir ./image
losetup -d "$LOOP_DEVICE"

printf "\n\n"

echo "Available hard drives:"
printf "\n"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
printf "\n"
echo "Enter the name of the hard drive to flash the image to."
echo "Enter it in the form of \"sdXX\" or \"mmcblkXX\" etc.."
printf "\n"
read -p ":" selected_drive
if [ -z "$selected_drive" ]; then
    echo "Invalid input. Exiting script."
    exit
fi
echo "You have chosen to flash to '/dev/$selected_drive'."
echo "You can also cancel and write the image to disk yourself."
read -p "Do you want to proceed? (y/n): " confirm
printf "\n"

if [ "$confirm" != "y" ]; then
    echo "Operation canceled. Exiting."
    exit 1
fi
echo "Flashing the image. Please wait..."
dd if="./debian.img" of="/dev/$selected_drive" bs=4M status=progress
sync
eject /dev/$selected_drive

rm ./debian.img

echo "You can now remove the SD-Card"