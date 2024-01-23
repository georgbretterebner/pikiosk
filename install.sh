#!/bin/bash

apt update && apt upgrade -y

apt install weston chromium-browser xwayland -y

useradd -m kiosk
mkdir /home/kiosk/.config
cp weston.ini /home/kiosk/.config
cp kiosk.sh /home/kiosk
cp kiosk.service /etc/systemd/system
systemctl daemon-reload
systemctl enable kiosk.service
cp 61-evdev-local.hwdb /etc/udev/hwdb.d
cp 99-touch-mirror.rules /etc/udev/rules.d
ln -sf /dev/null /etc/udev/rules.d/90-libinput-fuzz-override.rules
systemd-hwdb update
systemctl disable getty@.service
chown -R kiosk /home/kiosk
rm -rf /usr/share/icons/Adwaita/cursors/*
cp left_ptr /usr/share/icons/Adwaita/cursors

echo "NAutoVTs=0" >> /etc/systemd/logind.conf
echo "ReserveVT=0" >> /etc/systemd/logind.conf
echo " quiet nosplash loglevel=0 vt.global_cursor_default=0" >> /boot/cmdline.txt
echo " avoid_warnings=1" >> /boot/config.txt
echo " disable_splash=1" >> /boot/config.txt

systemctl disable keyboard-setup.service
systemctl disable dphys-swapfile.service
systemctl disable avahi-daemon.service
systemctl disable sys-kernel-debug.mount
systemctl disable raspi-config.service
systemctl disable systemd-udev-trigger.service
systemctl disable rpi-eeprom-update.service
systemctl disable rsyslog.service
systemctl disable systemd-journald.service
systemctl disable systemd-fsck-root.service
systemctl disable systemd-logind.service
systemctl disable bluetooth.service
systemctl disable hciuart.service

reboot