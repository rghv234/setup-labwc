#!/bin/sh

# Basic OS configuration
sed -i -r 's|#PermitRootLogin.*|PermitRootLogin no|g' /etc/ssh/sshd_config
rc-service sshd restart; rc-update add sshd default

cat > /root/.cshrc << EOF
unsetenv DISPLAY || true
HISTCONTROL=ignoreboth
EOF

cat > /etc/apk/repositories << EOF
http://dl-4.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-4.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
EOF

apk update
apk add tcsh && add-shell '/bin/csh'

# Setup user
adduser -D -g "" -u 998 -h /opt/daru -s /bin/csh daru
echo "daru:daru" | chpasswd
mkdir -p /opt/daru
cat > /opt/daru/.cshrc << EOF
unsetenv DISPLAY
export PAGER=less
set autologout = 6
set prompt = "$ "
set history = 0
set ignoreeof
EOF
cp /opt/daru/.cshrc /opt/daru/.bashrc
chown -R daru:daru /opt/daru

# Install essential packages
apk update
apk add mandoc man-pages nano binutils coreutils readline \
  sed attr dialog lsof less groff wget curl terminus-font \
  file lz4 gawk tree pciutils usbutils lshw tzdata tzdata-utils \
  zip p7zip xz tar cabextract cpio binutils lha acpi musl-locales musl-locales-lang \
  e2fsprogs btrfs-progs exfat-utils f2fs-tools dosfstools xfsprogs jfsutils \
  arch-install-scripts util-linux docs

# Set console font
apk add font-terminus
setfont /usr/share/consolefonts/ter-120n.psf.gz
sed -i "s#.*consolefont.*=.*#consolefont=\"ter-120n.psf.gz\"#g" /etc/conf.d/consolefont
rc-update add consolefont boot

# System users setup
apk add bash shadow shadow-uidmap shadow-login doas lang musl-locales
cat > /etc/doas.d/apkgeneral.conf << EOF
permit nopass general as root cmd apk
permit keepenv daru as root
EOF

mkdir /etc/skel
cat > /etc/skel/.cshrc << EOF
set history = 10000
set prompt = "$ "
EOF
cat > /etc/skel/.bashrc << EOF
set history = 10000
set prompt = "$ "
EOF
cat > /etc/skel/.Xresources << EOF
Xft.antialias: 1
Xft.rgba:      rgb
Xft.autohint:  0
Xft.hinting:   1
Xft.hintstyle: hintslight
EOF
cat > /etc/default/useradd << EOF
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=yes
EOF
cat > /etc/login.defs << EOF
USERGROUPS_ENAB yes
SYSLOG_SU_ENAB yes
SYSLOG_SG_ENAB yes
SULOG_FILE /var/log/sulog
SU_NAME su
EOF
useradd -m -U -c "" -G wheel,input,disk,floppy,cdrom,dialout,audio,video,lp,netdev,games,users,ping general
for u in $(ls /home); do for g in disk lp floppy audio cdrom dialout video lp netdev games users ping; do addgroup $u $g; done; done
for u in $(ls /home); do chown -R $u:$u /home/$u; done
echo "general:general" | chpasswd

# Hardware support setup
apk add acpi acpid acpid-openrc alpine-conf eudev eudev-doc eudev-rule-generator eudev-openrc pciutils util-linux arch-install-scripts zram-init acpi-utils rsyslog \
  fuse fuse-exfat-utils avfs pcre2 cpufreqd bluez bluez-deprecated bluez-openrc wpa_supplicant dhcpcd chrony macchanger wireless-tools iputils linux-firmware \
  networkmanager networkmanager-lang networkmanager-openvpn networkmanager-openvpn-lang

modprobe btusb && echo "btusb" >> /etc/modprobe
setup-devd udev
rc-update add rsyslog
rc-update add udev
rc-update add acpid
rc-update add cpufreqd
rc-update add fuse
rc-update add bluetooth
rc-update add chronyd
rc-update add wpa_supplicant
rc-update add networkmanager

# Start services
for svc in networking wpa_supplicant bluetooth udev fuse cpufreqd rsyslog; do rc-service $svc restart; done

# Audio and video setup
apk add mesa mesa-gl mesa-utils mesa-osmesa mesa-egl mesa-gles mesa-dri-gallium mesa-va-gallium libva-intel-driver intel-media-driver \
  xf86-video-intel xf86-video-amdgpu xf86-video-nouveau xf86-video-ati xf86-input-evdev xf86-video-modesetting xf86-input-libinput \
  linux-firmware-amdgpu linux-firmware-radeon linux-firmware-nvidia linux-firmware-i915 linux-firmware-intel dbus dbus-x11 udisks2

dbus-uuidgen > /var/lib/dbus/machine-id
rc-update add dbus
apk add font-noto-all ttf-dejavu ttf-linux-libertine ttf-liberation font-bitstream-type1 font-adobe-utopia-type1 font-isas-misc
apk add alsa-lib alsa-utils alsa-plugins alsa-tools alsaconf sndio pipewire pipewire-pulse pipewire-alsa pipewire-spa-bluez wireplumber-logind

modprobe snd-pcm-oss
modprobe snd-mixer-oss
echo -e "snd-pcm-oss\nsnd-mixer-oss" >> /etc/modules
rc-service alsa restart
amixer sset Master unmute
amixer sset PCM unmute
amixer set Master 100%
amixer set PCM 100%

cat > /etc/security/limits.d/audio-limits.conf << EOF
@audio - memlock 4096
@audio - nice -11
@audio - rtprio 88
@pipewire - memlock 4194304
@pipewire - nice -19
@pipewire - rtprio 95
EOF
rc-update add alsa
rc-service dbus restart
rc-service alsa restart

# Wayland setup
apk add gtk-update-icon-cache xdg-user-dirs xdg-desktop-portal-gtk xdg-desktop-portal-wlr hicolor-icon-theme \
  paper-gtk-theme adwaita-icon-theme numix-icon-theme numix-themes numix-themes-gtk2 numix-themes-gtk3 \
  xwayland wayland-libs-server wlr-randr wayland wlroots foot sway sway-doc bemenu wmenu grim swaylock swaylockd swaybg swayidle weston \
  foot-themes foot-extra-terminfo foot-bash-completion foot-fish-completion

apk add elogind elogind-openrc greetd greetd-gtkgreet cage polkit polkit-openrc polkit-elogind networkmanager-elogind linux-pam network-manager-applet vte3 shadow-login

# Configure Greetd
cat > /etc/greetd/config.toml << EOF
[terminal]
vt = next
switch = true
[default_session]
command = "cage -s -m extend -- gtkgreet"
user = greetd
EOF
cat > /etc/conf.d/greetd << EOF
cfgfile="/etc/greetd/config.toml"
rc_need=elogind
EOF
cat > /etc/greetd/environments <<EOF
dbus-run-session -- labwc
dbus-run-session -- sway
dbus-run-session -- openbox-session
EOF

addgroup greetd video
rc-update add elogind
rc-update add polkit
rc-update add greetd
for svc in networking networkmanager elogind polkit greetd; do rc-service $svc restart; done

# Install and configure Labwc
apk add labwc labwc-doc dunst redshift grim wl-clipboard clipman wvkbd wtype wdisplays kanshi swayimg zathura zathura-ps zathura-pdf-poppler \
  wlogout swaybg swaylock-effects swaylockd wlsunset sfwbar font-jetbrains-mono wezterm-fonts nwg-launchers wayvnc wf-recorder
mkdir -p /etc/xdg/labwc
cat > /etc/xdg/labwc/autostart << EOF
swaybg -c 000000 -o * &
sfwbar &
EOF
echo "Setup complete."
