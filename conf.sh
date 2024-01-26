#!/bin/bash

./rmconf.sh &> /dev/null
source secrets &> /dev/null

if [ -z "$username" ] || [ -z "$password" ] || [ -z "$wifi_ssid" ] || [ -z "$wifi_password" ] || [ -z "$hostname" ]  || [ -z "$ip_addr" ]; then

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

  if [ -z "$ip_addr" ]; then
    echo "Using DHCP"
  else
    read -p "Enter Gateway IP: " ip_gw
    read -p "Enter DNS Server IP: " ip_dns
  fi

fi

if [ -z "$username" ] || [ -z "$password" ] || [ -z "$wifi_ssid" ] || [ -z "$wifi_password" ] || [ -z "$hostname" ]; then
  echo "Invalid input. Exiting script."
  exit 1
fi


cat <<EOF > 25-wlan.network
[Match]
Name=wlan0

EOF

if [ -z "$ip_addr" ]; then

cat <<EOF >> 25-wlan.network
[Network]
DHCP=ipv4
EOF

echo "nameserver 1.1.1.1" > resolv.conf

else
  
cat <<EOF >> 25-wlan.network
[Network]
Address=$ip_addr
Gateway=$ip_gw
DNS=$ip_dns
EOF

cat <<EOF >> resolv.conf
nameserver $ip_dns
nameserver 1.1.1.1
EOF

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

export DEBIAN_FRONTEND=noninteractive

apt update && apt upgrade -y
apt install kbd cog sudo libgles2 -y

echo "Creating user 'kiosk'..."
useradd -m kiosk
usermod -aG video kiosk
usermod -aG input kiosk

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling kiosk service..."
systemctl enable kiosk.service

echo "Copying hardware database files..."
mv /kiosksetup/61-evdev-local.hwdb /etc/udev/hwdb.d
mv /kiosksetup/99-touch-mirror.rules /etc/udev/rules.d

echo "Creating symbolic link to override libinput rules..."
ln -sf /dev/null /etc/udev/rules.d/90-libinput-fuzz-override.rules

echo "Updating hardware database..."
systemd-hwdb update

echo "Disabling getty service..."
systemctl disable getty@.service

echo "Changing ownership of /home/kiosk to user 'kiosk'..."
chown -R kiosk /home/kiosk

echo "Setting logind configuration options..."
echo "NAutoVTs=0" >> /etc/systemd/logind.conf
echo "ReserveVT=10" >> /etc/systemd/logind.conf

echo "Updating boot command line options..."
echo " quiet nosplash loglevel=0 vt.global_cursor_default=0" | tee -a /boot/cmdline.txt
echo "avoid_warnings=1" | tee -a /boot/config.txt
echo "disable_splash=1" | tee -a /boot/config.txt

echo "$hostname" > /etc/hostname
systemctl enable ssh

passwd -l root
useradd -m $username
echo '$username:$password' | chpasswd
usermod -aG sudo $username
chsh r3 -s /bin/bash

rm -rf /kiosksetup
reboot

EOF

cat <<EOF > kiosk.service

[Unit]
Description=Fullscreen Kiosk
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
ExecStart=/usr/bin/cog $url

IgnoreSIGPIPE=no

[Install]
WantedBy=multi-user.target

EOF