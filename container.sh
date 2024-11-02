#!/bin/sh

# Ensure the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Update system and install essential dependencies
echo "Updating system and installing dependencies..."
apk update && apk upgrade
apk add alpine-sdk git build-base linux-headers python3 python3-dev \
    wayland wayland-protocols mesa-dri-gallium mesa-egl weston \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack pipewire-media-session \
    xwayland dbus dbus-openrc containerd lxc lxc-templates curl wget \
    btrfs-progs rsync tar shadow cgroup-tools

# Install and configure Waydroid
echo "Installing Waydroid..."
git clone https://github.com/waydroid/waydroid.git /tmp/waydroid
cd /tmp/waydroid
./scripts/setup-waydroid.sh

# Enable necessary services for Waydroid
echo "Enabling Waydroid services..."
rc-update add containerd default
rc-service containerd start

echo "Configuring Waydroid for low-end devices..."
waydroid init -f
waydroid prop set persist.waydroid.multi_windows true
waydroid prop set persist.waydroid.width 720
waydroid prop set persist.waydroid.height 1280
waydroid prop set persist.waydroid.force_rendering true

# Optimize Waydroid's container runtime
echo "Applying resource limitations for Waydroid..."
mkdir -p /etc/waydroid
cat <<EOF > /etc/waydroid/waydroid.conf
[container]
cgroup_limit_mem = 512M
cgroup_limit_cpu = 1
disable_gpu_compositing = true
EOF

# Install and configure Distrobox
echo "Installing Distrobox..."
apk add podman
curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh

echo "Creating a default Distrobox container for optimized use..."
distrobox-create -n alpine-container -i alpine:latest

# Configure Distrobox to run efficiently on low-end devices
echo "Optimizing Distrobox settings..."
cat <<EOF >> ~/.distroboxrc
PREFER_HOST_TERM=false
USE_HOST_HOME=false
PREFER_PODMAN=true
MEMORY_LIMIT=512m
CPU_SHARES=1024
EOF

# Add Distrobox init to .profile for seamless integration
if ! grep -q "distrobox enter" ~/.profile; then
    echo 'distrobox enter alpine-container' >> ~/.profile
fi

# Optimize Waydroid and Distrobox integration with power management tools
echo "Applying power management settings..."
cpupower frequency-set -g powersave
tlp start
powertop --auto-tune

# Setting up system optimizations for Waydroid and Distrobox
echo "Applying kernel tuning parameters for smoother container performance..."
cat <<EOF >> /etc/sysctl.conf
vm.swappiness = 1
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 0
EOF
sysctl -p

# Applying GPU optimizations
echo "Optimizing GPU settings for low-end devices..."
cat <<EOF > /etc/modprobe.d/mesa.conf
options i915 enable_psr=1
options radeon si_support=0
options amdgpu dc=0
EOF

# Configuring systemd replacement for resource management (if not using OpenRC)
if command -v systemctl >/dev/null 2>&1; then
    echo "Configuring systemd slice for container services..."
    cat <<EOF > /etc/systemd/system/waydroid.slice
[Slice]
CPUAccounting=yes
CPUQuota=50%
MemoryAccounting=yes
MemoryHigh=512M
EOF
    systemctl enable waydroid.slice
fi

# Final notes
echo "Waydroid and Distrobox installation and optimization complete."
echo "Please reboot your system to apply all changes."

exit 0
