#!/bin/bash

CEF_DL_LINK="https://cef-builds.spotifycdn.com/cef_binary_120.2.7%2Bg4bc6a59%2Bchromium-120.0.6099.234_linuxarm64_client.tar.bz2"
DEBIAN_DL_LINK="https://raspi.debian.net/daily/raspi_3_bookworm.img.xz"

# To get the newest download link for cef please visit and copy
#   the link from: Current Stable Build - Sample Application
#
# https://cef-builds.spotifycdn.com/index.html#linuxarm64
#
# For debian please go to and copy the desired Link
# https://raspi.debian.net/daily-images/

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

umount ./image
losetup -d "$LOOP_DEVICE"
