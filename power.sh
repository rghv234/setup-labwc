#!/bin/sh

# Ensure the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

echo "Updating system and installing essential tools..."
# Update system
apk update && apk upgrade

# Install essential packages
apk add busybox toybox wayland wayland-protocols mesa-dri-gallium \
    mesa-egl mesa-vulkan-intel mesa-vulkan-radeon sway swaylock \
    swaybg waybar power-profiles-daemon tlp powertop cpupower \
    firejail openrc eudev mdev cpufrequtils smartmontools \
    NetworkManager flatpak btrfs-progs f2fs-tools auto-cpufreq

# Enable necessary services
echo "Enabling and starting services..."
rc-update add eudev default
rc-update add NetworkManager default
rc-update add tlp default
rc-service eudev start
rc-service NetworkManager start
rc-service tlp start

# Tuning CPU power management
echo "Configuring CPU power management..."
cpupower frequency-set -g powersave
cpupower frequency-info

# Auto CPU frequency scaling daemon
echo "Enabling auto-cpufreq..."
rc-update add auto-cpufreq default
rc-service auto-cpufreq start

# TLP Configuration (Power Management)
echo "Configuring TLP settings..."
sed -i 's/^#CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT="powersave"/' /etc/tlp.conf
sed -i 's/^#CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC="powersave"/' /etc/tlp.conf
sed -i 's/^#USB_AUTOSUSPEND=.*/USB_AUTOSUSPEND=1/' /etc/tlp.conf
sed -i 's/^#SATA_LINKPWR_ON_BAT=.*/SATA_LINKPWR_ON_BAT=min_power/' /etc/tlp.conf

# Configure storage (noatime to reduce disk access)
echo "Optimizing filesystem..."
mount | grep -E '^/dev/(sd|nvme|mmcblk)' | awk '{print $1,$3}' | while read -r DEVICE MOUNTPOINT; do
    if ! grep -q "$DEVICE.*noatime" /etc/fstab; then
        echo "Adding noatime to $DEVICE"
        sed -i "s|${DEVICE}.*${MOUNTPOINT}|${DEVICE} ${MOUNTPOINT} noatime,defaults 0 0|" /etc/fstab
    fi
done

# Install and set up Powertop for further tuning
echo "Tuning power settings using Powertop..."
powertop --auto-tune

# Set kernel tuning parameters
echo "Setting kernel tuning parameters..."
cat <<EOF >> /etc/sysctl.conf
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF
sysctl -p

# NetworkManager power-saving settings
echo "Optimizing NetworkManager power settings..."
nmcli connection modify $(nmcli -t -f NAME c show --active) 802-11-wireless.powersave 3

# Install LibreWolf Browser with power efficiency tweaks
echo "Setting up LibreWolf Browser..."
apk add flatpak
flatpak install -y flathub io.gitlab.librewolf-community

# Create LibreWolf launch script with performance tweaks
echo "Tweaking LibreWolf for power efficiency..."
mkdir -p /etc/librewolf
cat <<EOF > /etc/librewolf/librewolf-flags.conf
--disable-accelerated-video-decode
--disable-accelerated-2d-canvas
--disable-accelerated-vpx-decode
--disable-background-networking
--enable-low-end-device-mode
--disable-gpu-vsync
--disable-webgl
--disable-features=PictureInPicture
--enable-features=BatterySaver,OptimizeFontsForEnergyUse
--no-referrers
EOF

# Adjust LibreWolf settings for performance and power efficiency
echo "Adjusting LibreWolf user preferences..."
LIBREWOLF_PREF_DIR="/var/lib/flatpak/app/io.gitlab.librewolf-community/current/active/files/librewolf"
mkdir -p "$LIBREWOLF_PREF_DIR"
cat <<EOF > "$LIBREWOLF_PREF_DIR/prefs.js"
// Performance tweaks
user_pref("browser.tabs.animate", false);
user_pref("browser.sessionstore.restore_on_demand", true);
user_pref("media.autoplay.default", 5);
user_pref("layers.acceleration.disabled", true);
user_pref("media.hardware-video-decoding.enabled", false);
user_pref("gfx.webrender.enabled", false);
user_pref("dom.ipc.processCount", 2); // Limit content processes
user_pref("network.prefetch-next", false);
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", true);
user_pref("browser.cache.memory.capacity", 1048576); // Limit memory cache
EOF


# Mount tweaks for SSD (if applicable)
echo "Applying SSD optimization..."
if grep -q "SSD" /sys/block/*/device/model; then
    echo "Enabling trim service for SSD..."
    apk add fstrim
    rc-update add fstrim default
    rc-service fstrim start
fi

# Install Flatpak & Enable Flathub
echo "Setting up Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update

# Configure Labwc (Optional: Uncomment if using Labwc instead of Sway)
# echo "Setting up Labwc..."
# apk add labwc
# if ! grep -q "exec labwc" ~/.profile; then
#     echo "exec labwc" >> ~/.profile
# fi

# Configure Coreboot (if applicable)
echo "Checking for Coreboot compatibility..."
if [ -d /sys/firmware ]; then
    echo "Your system may support Coreboot. Consider flashing for better power efficiency."
fi

echo "System power efficiency tuning is complete. Please reboot for all changes to take effect."

exit 0
