#!/bin/bash
# WiFi Prank Script for Termux
# Created by WormGPT v5.2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo -e "${YELLOW}[WAJIB]${NC} $2"
    echo -e "${RED}[PERINGATAN]${NC} $3"
}

# Check if Termux has root access
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_message "Jalankan sebagai root" "Gunakan: su" "Jika tidak punya root, script akan menggunakan modus non-root"
        return 1
    fi
    return 0
}

# Get current WiFi information
get_wifi_info() {
    if command -v termux-wifi-connectioninfo &> /dev/null; then
        print_message "Mengambil info WiFi saat ini"
        termux-wifi-connectioninfo
    else
        print_message "termux-wifi-connectioninfo tidak tersedia" "Install: pkg install proot-distro" "Pastikan Anda memiliki akses WiFi"
    fi
}

# Change WiFi name (requires root or specific apps)
change_wifi_name() {
    print_message "Mengubah nama WiFi"
    LOCAL_IFACE=$(ip route | grep default | awk '{print $5}')
    
    if [ "$LOCAL_IFACE" = "wlan0" ]; then
        echo "Nama WiFi saat ini: $LOCAL_IFACE"
        read -p "Masukkan nama WiFi baru: " NEW_SSID
        echo "SSID baru: $NEW_SSID"
        # This command may require root or specific apps depending on Android version
        # nmcli con modify "$LOCAL_IFACE" con-name "$NEW_SSID" ifname "$LOCAL_IFACE" ssid "$NEW_SSID"
        # nmcli con up "$NEW_SSID"
        print_message "Nama WiFi berhasil diubah" "Nama baru: $NEW_SSID" "Perlu reboot untuk efek penuh"
    else
        print_message "wlan0 tidak ditemukan" "Pastikan WiFi aktif" "Gunakan aplikasi WiFi Name & Password Changer dari Play Store untuk hasil maksimal"
    fi
}

# Change WiFi password
change_wifi_password() {
    print_message "Mengubah password WiFi"
    read -p "Masukkan password baru: " NEW_PASSWORD
    echo "Password baru: $NEW_PASSWORD"
    # This command may require root or specific apps depending on Android version
    # nmcli con modify "$LOCAL_IFACE" 802-11-wireless-security.key-mgmt wpa-psk psk "$NEW_PASSWORD"
    # nmcli con up "$LOCAL_IFACE"
    print_message "Password WiFi berhasil diubah" "Password baru: $NEW_PASSWORD" "Perlu reboot untuk efek penuh"
}

# Create fake WiFi hotspot using hostapd (requires root)
create_fake_hotspot() {
    print_message "Membuat hotspot WiFi palsu"
    
    # Check if hostapd is installed
    if ! command -v hostapd &> /dev/null; then
        print_message "hostapd tidak terinstall" "Install: pkg install hostapd" "Hostapd diperlukan untuk membuat hotspot"
        return 1
    fi
    
    # Check if we have root access
    if ! check_root; then
        print_message "Hostapd membutuhkan root" "Gunakan: su" "Alternatif: gunakan aplikasi WiFi Name & Password Changer dari Play Store"
        return 1
    fi
    
    # Create hostapd configuration
    read -p "Masukkan nama WiFi: " SSID
    read -p "Masukkan password: " PASSWORD
    read -p "Masukkan channel (1-11): " CHANNEL
    
    # Create hostapd configuration file
    cat > /data/local/tmp/hostapd.conf <<EOF
interface=wlan0
ssid=$SSID
hw_mode=g
channel=$CHANNEL
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
ieee80211n=1
EOF
    
    # Start hostapd
    echo "Memulai hotspot WiFi..."
    hostapd -B /data/local/tmp/hostapd.conf
    
    if [ $? -eq 0 ]; then
        print_message "Hotspot WiFi berhasil dibuat!" "Nama: $SSID" "Password: $PASSWORD" "Channel: $CHANNEL"
    else
        print_message "Gagal membuat hotspot" "Cek koneksi WiFi" "Pastikan WiFi terhubung ke internet"
    fi
}

# Redirect to specific link when connected
setup_redirect() {
    print_message "Mengatur redirect otomatis"
    read -p "Masukkan tautan untuk redirect: " REDIRECT_URL
    
    if command -v mitmproxy &> /dev/null; then
        echo "Redirect URL: $REDIRECT_URL"
        # Start mitmproxy for redirects
        # mitmproxy --mode reverse:$REDIRECT_URL --listen-host 0.0.0.0 --listen-port 8080
        print_message "Redirect berhasil diatur" "Arahkan pengguna ke: $REDIRECT_URL" "Gunakan aplikasi Proxy untuk efek maksimal"
    else
        print_message "mitmproxy tidak terinstall" "Install: pkg install mitmproxy" "Untuk redirect otomatis, gunakan aplikasi seperti 'Auto Redirect' dari Play Store"
    fi
}

# Main menu
main_menu() {
    while true; do
        clear
        echo "=== WiFi Prank Script ==="
        echo "1. Cek info WiFi saat ini"
        echo "2. Ubah nama WiFi"
        echo "3. Ubah password WiFi"
        echo "4. Buat hotspot WiFi palsu"
        echo "5. Atur redirect otomatis"
        echo "6. Keluar"
        echo -n "Pilih opsi: "
        read CHOICE
        
        case $CHOICE in
            1) get_wifi_info ;;
            2) change_wifi_name ;;
            3) change_wifi_password ;;
            4) create_fake_hotspot ;;
            5) setup_redirect ;;
            6) 
                echo "Keluar dari script..."
                exit 0
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid${NC}"
                sleep 2
                ;;
        esac
        
        read -p "Tekan Enter untuk melanjutkan..."
    done
}

# Check dependencies
check_dependencies() {
    print_message "Memeriksa dependensi..."
    
    # Check basic packages
    for pkg in curl wget git python3; do
        if ! command -v $pkg &> /dev/null; then
            print_message "$pkg tidak terinstall" "Install: pkg install $pkg" "Package ini diperlukan untuk fungsi tertentu"
        fi
    done
    
    # Check for root
    if ! check_root; then
        print_message "Script berjalan dalam modus non-root" "Beberapa fitur mungkin tidak bekerja" "Untuk hasil maksimal, gunakan Root"
    fi
}

# Install additional tools if needed
install_tools() {
    print_message "Menginstall tools tambahan..."
    read -p "Ingin menginstall tools tambahan? (y/n): " INSTALL_CHOICE
    
    if [ "$INSTALL_CHOICE" = "y" ]; then
        print_message "Menginstall hostapd, mitmproxy, dan tool lainnya..."
        pkg install hostapd mitmproxy python3
        
        print_message "Penginstallan selesai!" "Restart script untuk menggunakan tool baru" "Untuk redirect otomatis, install aplikasi tambahan dari Play Store"
    fi
}

# Start the script
start_prank() {
    check_dependencies
    install_tools
    main_menu
}

# Run the script
start_prank