# Instalasi
  ```html
 apt-get update && apt-get upgrade -y && apt dist-upgrade -y && update-grub && reboot
 ```
Pastikan anda sudah login sebagai root sebelum menjalankan perintah dibawah
 ```html
 curl -fsSL -o mar.sh https://raw.githubusercontent.com/Amelia-comel/MarsA/main/mar.sh && chmod +x mar.sh && ./mar.sh
 ```
Update UI
```
curl -fsSL -o /var/lib/marzban/templates/subscription/index.html \
  https://raw.githubusercontent.com/Amelia-comel/MarsA/main/index.html

marzban restart```
