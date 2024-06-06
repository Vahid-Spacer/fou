#!/bin/bash
CONFIG_FILE="/etc/fou_tunnel_config"
SERVICE_FILE="/etc/systemd/system/fou-tunnel.service"
echo -e "\033c"
echo -e "\e[1;32m

 Local Fou Tunnel

\e[0m"

if [ ! -f "$CONFIG_FILE" ]; then
    # آدرس‌های IP دو سرور را وارد کنید
    read -p "Enter local IP address: " LOCAL_IP
    read -p "Enter remote IP address: " REMOTE_IP
    read -p "Enter local tunnel IP (e.g., 10.20.30.*): " LOCAL_TUNNEL_IP
    read -p "Enter remote tunnel IP (e.g., 10.20.30.*): " REMOTE_TUNNEL_IP

    # ذخیره IPها در فایل تنظیمات
    echo "LOCAL_IP=$LOCAL_IP" > $CONFIG_FILE
    echo "REMOTE_IP=$REMOTE_IP" >> $CONFIG_FILE
    echo "LOCAL_TUNNEL_IP=$LOCAL_TUNNEL_IP" >> $CONFIG_FILE
    echo "REMOTE_TUNNEL_IP=$REMOTE_TUNNEL_IP" >> $CONFIG_FILE
else
    # خواندن IPها از فایل تنظیمات
    source $CONFIG_FILE
fi

FOU_PORT=5555

# ماژول‌های مورد نیاز را بارگذاری کنید
sudo modprobe fou
sudo modprobe ip_gre

# ساخت سوکت FOU برای GRE
sudo ip fou add port $FOU_PORT ipproto gre

# ایجاد رابط تونل GRE با بسته‌بندی FOU
sudo ip link add gre1 type gre key 1 remote $REMOTE_IP local $LOCAL_IP ttl 255 encap fou encap-sport $FOU_PORT encap-dport $FOU_PORT

# تخصیص آدرس IP به تونل GRE
sudo ip addr add $LOCAL_TUNNEL_IP/24 dev gre1

# فعال کردن رابط GRE
sudo ip link set gre1 up

# اضافه کردن مسیر برای شبکه از راه دور
sudo ip route add $REMOTE_TUNNEL_IP/32 dev gre1

# اجازه ترافیک UDP در پورت 5555 را بدهید
sudo iptables -A INPUT -p udp --dport $FOU_PORT -j ACCEPT
sudo iptables -A OUTPUT -p udp --sport $FOU_PORT -j ACCEPT

echo "FOU tunnel has been configured between $LOCAL_IP and $REMOTE_IP"

# ایجاد فایل سرویس systemd
sudo bash -c "cat > $SERVICE_FILE" << EOL
[Unit]
Description=FOU Tunnel Setup
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $0
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOL

# فعال‌سازی سرویس
sudo systemctl daemon-reload
sudo systemctl enable fou-tunnel.service
sudo systemctl start fou-tunnel.service

echo "FOU tunnel service has been created and started."

#
nano setup_fou_tunnel.sh
chmod +x setup_fou_tunnel.sh
sudo ./setup_fou_tunnel.sh
