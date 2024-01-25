#!/bin/bash

read -p "Enter username: " username
read -s -p "Enter password: " password
echo
read -p "Enter your WiFi SSID: " wifi_ssid
read -s -p "Enter your WiFi password: " wifi_password
echo
read -p "Enter hostname: " hostname
read -p "Enter webpage to display on kiosk: " url
echo "Enter IP Address and Subnet-Mask in \"1.2.3.4/24\" format. "
read -p "Leave Empty for DHCP. IP: " ip_addr

if [ -z "$username" ] || [ -z "$password" ] || [ -z "$wifi_ssid" ] || [ -z "$wifi_password" ] || [ -z "$hostname" ]; then
    echo "Invalid input. Exiting script."
    exit 1
fi

cat <<EOF > 25-wlan.network
[Match]
Name=wlan0

EOF

if [ -z "$ip_addr" ]; then
  echo "Using DHCP"

cat <<EOF >> 25-wlan.network
[Network]
DHCP=ipv4
EOF

echo "nameserver 1.1.1.1" > resolv.conf

else
  read -p "Enter Gateway IP: " ip_gw
  read -p "Enter DNS Server IP: " ip_dns
  
cat <<EOF >> 25-wlan.network
[Network]
Address=$ip_addr
Gateway=$ip_gw
DNS=$ip_dns
EOF

echo "nameserver $ip_dns" > resolv.conf

fi

cat <<EOF > wpa_supplicant-wlan0.conf
ctrl_interface=/run/wpa_supplicant
ctrl_interface_group=netdev
update_config=1

country=AT

network={
    ssid="$wifi_ssid"
    psk="$wifi_password"
}
EOF

cat <<EOF > firstboot.sh

apt update && apt upgrade -y
apt install xwayland cage sudo -y

echo "Creating user 'kiosk' with home directory..."
useradd -m kiosk

echo "Creating directory /home/kiosk/cef..."
mkdir /home/kiosk/cef

echo "Copying CEF binaries to /home/kiosk/cef..."
cp -r /kiosksetup/cef-bin/* /home/kiosk/cef

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling kiosk service..."
systemctl enable kiosk.service

echo "Copying hardware database files..."
cp /kiosksetup/61-evdev-local.hwdb /etc/udev/hwdb.d
cp /kiosksetup/99-touch-mirror.rules /etc/udev/rules.d

echo "Creating symbolic link to override libinput rules..."
ln -sf /dev/null /etc/udev/rules.d/90-libinput-fuzz-override.rules

echo "Updating hardware database..."
systemd-hwdb update

echo "Disabling getty service..."
systemctl disable getty@.service

echo "Changing ownership of /home/kiosk to user 'kiosk'..."
chown -R kiosk /home/kiosk

echo "Removing Adwaita cursor icons..."
rm -rf /usr/share/icons/Adwaita/cursors/*

echo "Copying custom cursor left_ptr to /usr/share/icons/Adwaita/cursors..."
cp /kiosksetup/left_ptr /usr/share/icons/Adwaita/cursors

echo "Setting logind configuration options..."
echo "NAutoVTs=0" >> /etc/systemd/logind.conf
echo "ReserveVT=10" >> /etc/systemd/logind.conf

echo "Updating boot command line options..."
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

echo "$hostname" > /etc/hostname
systemctl enable ssh

passwd -l root
useradd -m $username
echo '$username:$password' | chpasswd
usermod -aG sudo $username

rm -rf /kiosksetup
reboot

EOF

cat <<EOF > kiosk.service

[Unit]
Description=Cage Kiosk
RequiresMountsFor=/run
After=network-online.target

[Service]
User=kiosk
WorkingDirectory=/home/kiosk
PermissionsStartOnly=true
Restart=always
PAMName=login

UtmpIdentifier=tty1
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes

StandardOutput=tty
StandardInput=tty
StandardError=journal

ExecStartPre=/bin/chvt 1
ExecStart=/usr/bin/cage -- /home/kiosk/cef/cefsimple --url="$url"

IgnoreSIGPIPE=no

[Install]
WantedBy=multi-user.target

EOF