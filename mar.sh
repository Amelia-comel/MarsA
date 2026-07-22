#!/bin/bash
colorized_echo() {
    local color=$1
    local text=$2
    
    case $color in
        "red")
        printf "\e[91m${text}\e[0m\n";;
        "green")
        printf "\e[92m${text}\e[0m\n";;
        "yellow")
        printf "\e[93m${text}\e[0m\n";;
        "blue")
        printf "\e[94m${text}\e[0m\n";;
        "magenta")
        printf "\e[95m${text}\e[0m\n";;
        "cyan")
        printf "\e[96m${text}\e[0m\n";;
        *)
            echo "${text}"
        ;;
    esac
}

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    colorized_echo red "Error: Skrip ini harus dijalankan sebagai root."
    exit 1
fi

# Check supported operating system
supported_os=false

if [ -f /etc/os-release ]; then
    os_name=$(grep -E '^ID=' /etc/os-release | cut -d= -f2)
    os_version=$(grep -E '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

 if [ "$os_name" == "debian" ] && ([ "$os_version" == "11" ] || [ "$os_version" == "12" ]); then
    supported_os=true
    elif [ "$os_name" == "ubuntu" ] && [ "$os_version" == "20.04" ]; then
        supported_os=true
    fi
fi
apt install sudo curl -y
if [ "$supported_os" != true ]; then
    colorized_echo red "Error: Skrip ini hanya support di Debian 11/12 dan Ubuntu 20.04. Mohon gunakan OS yang di support."
    exit 1
fi

mkdir -p /etc/data

#domain
read -rp "Masukkan Domain: " domain
echo "$domain" > /etc/data/domain
domain=$(cat /etc/data/domain)

#email
read -rp "Masukkan Email anda: " email

#username
while true; do
    read -rp "Masukkan UsernamePanel (hanya huruf dan angka): " userpanel

    # Memeriksa apakah userpanel hanya mengandung huruf dan angka
    if [[ ! "$userpanel" =~ ^[A-Za-z0-9]+$ ]]; then
        echo "UsernamePanel hanya boleh berisi huruf dan angka. Silakan masukkan kembali."
    elif [[ "$userpanel" =~ [Aa][Dd][Mm][Ii][Nn] ]]; then
        echo "UsernamePanel tidak boleh mengandung kata 'admin'. Silakan masukkan kembali."
    else
        echo "$userpanel" > /etc/data/userpanel
        break
    fi
done

read -rp "Masukkan Password Panel: " passpanel
echo "$passpanel" > /etc/data/passpanel

#Preparation
clear
cd;
apt-get update;

#Remove unused Module
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

#install bbr
echo 'fs.file-max = 500000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 4000000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p;

#install toolkit
apt-get install libio-socket-inet6-perl libsocket6-perl libcrypt-ssleay-perl libnet-libidn-perl perl libio-socket-ssl-perl libwww-perl libpcre3 libpcre3-dev zlib1g-dev dbus iftop zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr dnsutils sudo at htop iptables bsdmainutils cron lsof lnav -y

#Set Timezone GMT+7
timedatectl set-timezone Asia/Jakarta;

#Install Marzban
sudo bash -c "$(curl -sL https://github.com/GawrAme/Marzban-scripts/raw/master/marzban.sh)" @ install

#Install Subs
wget -N -P /var/lib/marzban/templates/subscription/  https://raw.githubusercontent.com/Amelia-comel/MarsA/main/index.html

#install env
wget -O /opt/marzban/.env "https://raw.githubusercontent.com/Amelia-comel/MarsA/main/env"

#install Assets folder
mkdir -p /var/lib/marzban/assets
cd

#profile
echo -e 'profile' >> /root/.profile
wget -O /usr/bin/profile "https://raw.githubusercontent.com/Amelia-comel/MarsA/main/profile";
chmod +x /usr/bin/profile
apt install neofetch -y
wget -O /usr/bin/cekservice "https://raw.githubusercontent.com/Amelia-comel/MarsA/main/cekservice.sh"
chmod +x /usr/bin/cekservice

#install compose
wget -O /opt/marzban/docker-compose.yml "https://raw.githubusercontent.com/Amelia-comel/MarsA/main/docker-compose.yml"

#Install VNSTAT
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://github.com/Amelia-comel/MarsA/raw/main/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install 
cd
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz 
rm -rf /root/vnstat-2.6

#Install Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest -y

#install nginx
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log
wget -O /opt/marzban/nginx.conf "https://raw.githubusercontent.com/Amelia-comel/MarsA/main/nginx.conf"
wget -O /opt/marzban/default.conf "https://raw.githubusercontent.com/Amelia-comel/MarsA/main/vps.conf"
wget -O /opt/marzban/xray.conf "https://raw.githubusercontent.com/Amelia-comel/MarsA/main/xray.conf"
mkdir -p /var/www/html
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Technical Support</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background-color: #202124;
            color: #ffffff; /* Semua text berwarna putih */
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            overflow: hidden;
            text-align: center;
            cursor: pointer; /* Indikator bisa ditap di manapun */
            user-select: none;
        }
        
        /* Teks Offline ala Chrome */
        .error-code {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 10px;
            letter-spacing: 1px;
        }
        .error-desc {
            font-size: 14px;
            color: #ffffff;
            margin-bottom: 40px;
        }

        /* Container Animasi Dino */
        .game-container {
            position: relative;
            width: 100%;
            max-width: 600px;
            height: 150px;
            border-bottom: 2px solid #5f6368;
            margin-bottom: 40px;
            overflow: hidden;
        }

        .dino {
            position: absolute;
            bottom: 0;
            left: 10%;
            width: 44px;
            height: 47px;
            background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%23ffffff"><path d="M20 0h-9v2h-2v2h-2v2h-2v2h-2v2h-2v4h2v2h2v4h-2v2h4v-2h2v-4h2v4h2v2h4v-2h-2v-4h2v-2h2v-2h2v-8h-2v-2z"/></svg>');
            background-size: cover;
            animation: run 0.3s steps(2) infinite;
        }

        /* Animasi Lompat saat Layar Ditap */
        .dino.jump {
            animation: jump-anim 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
        }

        @keyframes run {
            0% { transform: translateY(0); }
            50% { transform: translateY(-4px); } 
        }

        @keyframes jump-anim {
            0%, 100% { bottom: 0; }
            50% { bottom: 70px; }
        }

        .cactus {
            position: absolute;
            bottom: 0;
            right: -50px;
            width: 20px;
            height: 40px;
            background-color: #ffffff;
            border-radius: 5px 5px 0 0;
            animation: move-left 1.5s linear infinite;
        }
        .cactus::before, .cactus::after {
            content: '';
            position: absolute;
            background-color: #ffffff;
            width: 12px;
            height: 20px;
            bottom: 10px;
            border-radius: 4px;
        }
        .cactus::before { left: -14px; border-radius: 4px 0 0 4px; }
        .cactus::after { right: -14px; bottom: 15px; border-radius: 0 4px 4px 0; }

        .cloud {
            position: absolute;
            top: 20px;
            width: 40px;
            height: 12px;
            background: #ffffff;
            border-radius: 20px;
            animation: move-left 4s linear infinite;
            opacity: 0.5;
        }
        .cloud::before, .cloud::after {
            content: '';
            position: absolute;
            background: #ffffff;
            border-radius: 50%;
        }
        .cloud::before { width: 20px; height: 20px; top: -10px; left: 5px; }
        .cloud::after { width: 15px; height: 15px; top: -5px; right: 5px; }

        @keyframes move-left {
            0% { right: -100px; }
            100% { right: 100%; }
        }

        .ground-line {
            position: absolute;
            bottom: -2px;
            width: 200%;
            height: 2px;
            background: repeating-linear-gradient(90deg, #202124 0, #202124 10px, #ffffff 10px, #ffffff 30px);
            animation: scroll-ground 1s linear infinite;
        }

        @keyframes scroll-ground {
            0% { transform: translateX(0); }
            100% { transform: translateX(-50%); }
        }

        /* Tombol Technical Support */
        .support-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 10px;
            font-size: 14px; /* Ukuran font diperkecil */
            font-weight: bold;
            letter-spacing: 0.5px;
            z-index: 10;
        }

        .contact-link {
            display: flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
            color: #ffffff;
            background: rgba(255, 255, 255, 0.1);
            padding: 8px 15px;
            border-radius: 20px;
            transition: background 0.3s;
        }

        .contact-link:hover {
            background: rgba(255, 255, 255, 0.2);
        }

        .telegram-logo {
            width: 20px;
            height: 20px;
            fill: #ffffff; /* Logo berwarna putih mengikuti font */
        }
    </style>
</head>
<body onclick="makeJump()">

    <!-- Teks Offline -->
    <div class="error-code">ERR_INTERNET_DISCONNECTED</div>
    <div class="error-desc">Check your network connection.</div>

    <!-- Animasi Dino -->
    <div class="game-container">
        <div class="cloud" style="animation-delay: 0s; top: 30px;"></div>
        <div class="cloud" style="animation-delay: 2s; top: 15px; width: 30px;"></div>
        <div class="ground-line"></div>
        <div class="dino" id="dinoPlayer"></div>
        <div class="cactus" style="animation-delay: 0s;"></div>
        <div class="cactus" style="animation-delay: 0.7s; height: 25px; right: -150px;"></div>
    </div>

    <!-- Teks dan Tombol Telegram (Bisa Diklik) -->
    <div class="support-container">
        <span>Technical Support</span>
        <a href="https://t.me/MediafairyCH" target="_blank" class="contact-link">
            <svg class="telegram-logo" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.664 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>
            </svg>
            <span class="handle">@dapur umkm</span>
        </a>
    </div>

    <!-- Script JavaScript untuk Fungsi Lompat -->
    <script>
        function makeJump() {
            var dino = document.getElementById("dinoPlayer");
            if (dino.classList != "jump") {
                dino.classList.add("jump");
                setTimeout(function() {
                    dino.classList.remove("jump");
                }, 500);
            }
        }
    </script>
</body>
</html>
EOF

#install socat
apt install iptables -y
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y 
apt install socat cron bash-completion -y

#install cert
curl https://get.acme.sh | sh -s email=$email
/root/.acme.sh/acme.sh --server letsencrypt --register-account -m $email --issue -d $domain --standalone -k ec-256 --debug
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /var/lib/marzban/xray.crt --keypath /var/lib/marzban/xray.key --ecc
wget -O /var/lib/marzban/xray_config.json "https://raw.githubusercontent.com/Amelia-comel/MarsA/main/xray_config.json"

#install firewall
apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8081/tcp
sudo ufw allow 1080/tcp
sudo ufw allow 1080/udp
yes | sudo ufw enable

#install database
wget -O /var/lib/marzban/db.sqlite3 "https://github.com/Amelia-comel/MarsA/raw/main/db.sqlite3"

#install WARP Proxy
wget -O /root/warp "https://raw.githubusercontent.com/hamid-gh98/x-ui-scripts/main/install_warp_proxy.sh"
sudo chmod +x /root/warp
sudo bash /root/warp -y 

#finishing
apt autoremove -y
apt clean
cd /opt/marzban
sed -i "s/# SUDO_USERNAME = \"admin\"/SUDO_USERNAME = \"${userpanel}\"/" /opt/marzban/.env
sed -i "s/# SUDO_PASSWORD = \"admin\"/SUDO_PASSWORD = \"${passpanel}\"/" /opt/marzban/.env
docker compose down && docker compose up -d
marzban cli admin import-from-env -y
sed -i "s/SUDO_USERNAME = \"${userpanel}\"/# SUDO_USERNAME = \"admin\"/" /opt/marzban/.env
sed -i "s/SUDO_PASSWORD = \"${passpanel}\"/# SUDO_PASSWORD = \"admin\"/" /opt/marzban/.env
docker compose down && docker compose up -d
cd
echo "Tunggu 30 detik untuk generate token API"
sleep 30s

#instal token
curl -X 'POST' \
  "https://${domain}/api/admin/token" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "grant_type=password&username=${userpanel}&password=${passpanel}&scope=&client_id=string&client_secret=string" > /etc/data/token.json
cd
touch /root/log-install.txt
echo -e "Untuk data login dashboard Marzban: 
-=================================-
URL HTTPS : https://${domain}/dashboard 
username  : ${userpanel}
password  : ${passpanel}
-=================================-
Jangan lupa join Channel & Grup Telegram saya juga di
Telegram Channel: https://t.me/MediafairyCH
-=================================-" > /root/log-install.txt
profile
colorized_echo green "Script telah berhasil di install"
rm /root/mar.sh
colorized_echo blue "Menghapus admin bawaan db.sqlite"
marzban cli admin delete -u admin -y
echo -e "[\e[1;31mWARNING\e[0m] Reboot sekali biar ga error lur [default y](y/n)? "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
cat /dev/null > ~/.bash_history && history -c && reboot
fi