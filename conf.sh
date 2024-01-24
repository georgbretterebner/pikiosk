#!/bin/bash

read -p "Enter username: " username
read -s -p "Enter password: " password
echo
read -p "Enter your WiFi SSID: " wifi_ssid
read -s -p "Enter your WiFi password: " wifi_password
echo
read -p "Enter hostname: " hostname

if [ -z "$username" ] || [ -z "$password" ] || [ -z "$wifi_ssid" ] || [ -z "$wifi_password" ] || [ -z "$hostname" ]; then
    echo "Invalid input. Exiting script."
    exit 1
fi

cat <<EOF > firstboot.sh

echo "$hostname" > /etc/hostname
systemctl enable ssh

passwd -l root
useradd -m $username
echo '$username:$password' | chpasswd
usermod -aG sudo $username

/kioskinstall/install.sh
reboot

EOF

cat <<EOF > 20-wireless.network
[Match]
Name=wlan0

[Network]
DHCP=yes

[Wireless]
SSID=$wifi_ssid
KeyManagement=WPA-PSK
PSK=$wifi_password

EOF