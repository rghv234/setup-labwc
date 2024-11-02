#!/bin/sh

# Alpine Linux Wi-Fi Configuration Script

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

echo "## Alpine Linux Wi-Fi Configuration Script ##"

# Check Wi-Fi status
echo "Checking available wireless devices..."
rfkill list

# Check if required packages are installed
echo "Installing required packages..."
apk add --no-cache wireless-tools wpa_supplicant linux-firmware util-linux arch-install-scripts

# Confirm installation
echo "Verifying installation of required packages..."
if apk info | grep -q "wireless-tools"; then
    echo "wireless-tools installed."
else
    echo "Failed to install wireless-tools."
fi

if apk info | grep -q "wpa_supplicant"; then
    echo "wpa_supplicant installed."
else
    echo "Failed to install wpa_supplicant."
fi

# Check network device status
echo "Checking network interface status..."
IFACE=$(rfkill list | grep -i wlan | awk '{print $1}')
if [ -z "$IFACE" ]; then
    echo "No wireless interface found."
    exit 1
fi

echo "Wireless interface detected: $IFACE"
echo "Checking soft/hard block status..."

# Check soft and hard block status
rfkill list $IFACE

# Unblock Wi-Fi if necessary
if rfkill list $IFACE | grep -q "Soft blocked: yes"; then
    echo "Unblocking Wi-Fi..."
    rfkill unblock wifi
    echo "Wi-Fi unblocked."
else
    echo "Wi-Fi is not soft blocked."
fi

if rfkill list $IFACE | grep -q "Hard blocked: yes"; then
    echo "Wi-Fi is hard blocked. Check hardware switch."
    exit 1
fi

# Wi-Fi configuration placeholder
echo "To configure Wi-Fi, please run the following command:"
echo "wpa_supplicant -B -i $IFACE -c /etc/wpa_supplicant/wpa_supplicant.conf"
echo "You may need to create or edit /etc/wpa_supplicant/wpa_supplicant.conf."

echo "## Script completed. ##"
