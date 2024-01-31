#!/bin/bash

DEBIAN_DL_LINK="https://downloads.raspberrypi.com/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2023-12-06/2023-12-05-raspios-bullseye-armhf-lite.img.xz"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

./conf.sh

echo "Downloading debian image..."
wget -nv --show-progress -O - $DEBIAN_DL_LINK | unxz > debian.img

LOOP_DEVICE=$(losetup -fP --show debian.img)

mkdir boot
mount "${LOOP_DEVICE}p1" ./boot

sync
umount ./boot
rmdir ./boot

mkdir image
mount "${LOOP_DEVICE}p2" ./image

mkdir ./image/kiosksetup
cp -r ./files/* ./image/kiosksetup
chown -R root ./image/kiosksetup

mv ./kiosk.sh ./image/kiosksetup
chmod +x ./image/kiosksetup/kiosk.sh

mv ./25-wlan.network ./image/etc/systemd/network
rm -f ./image/etc/resolv.conf
mv ./resolv.conf ./image/etc

mv ./image/etc/network/interfaces ./image/etc/network/interfaces.save
mv ./image/etc/network/interfaces.d ./image/etc/network/interfaces.d.save

rm -f ./image/etc/systemd/system/network-online.target.wants/*
rm -f ./image/etc/systemd/system/multi-user.target.wants/*

ln -s ./image/usr/lib/systemd/system/systemd-networkd.service ./image/etc/systemd/system/network-online.target.wants
ln -s ./image/usr/lib/systemd/system/systemd-networkd.service ./image/etc/systemd/system/multi-user.target.wants

mv ./wpa_supplicant-wlan0.conf ./image/etc/wpa_supplicant
ln -s ./image/lib/systemd/system/wpa_supplicant@.service ./image/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service

cp ./files/firstboot.service ./image/lib/systemd/system
ln -s ./image/lib/systemd/system/firstboot.service ./image/etc/systemd/system/multi-user.target.wants/firstboot.service

mv ./firstboot.sh ./image/kiosksetup
chmod +x ./image/kiosksetup/firstboot.sh

mv ./kiosk.service ./image/etc/systemd/system
#rm -f ./image/etc/systemd/system/getty.target.wants/*

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