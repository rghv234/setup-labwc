#!/bin/sh

# Update and install necessary packages
apk update
apk add pcmanfm gtk-mushroom-themes git rofi foot

# Clone the Orchis theme repository
if [ ! -d "$HOME/Orchis-theme" ]; then
    git clone https://github.com/vinceliuice/Orchis-theme.git "$HOME/Orchis-theme"
fi

# Install Orchis theme
cd "$HOME/Orchis-theme"
bash install.sh

# Create a configuration file for Labwc
mkdir -p "$HOME/.config/labwc"
cat <<EOL > "$HOME/.config/labwc/labwc.conf"
# Labwc configuration for Orchis theme
theme = "Orchis"
EOL

# Create a configuration file for PCManFM and disable desktop icons
mkdir -p "$HOME/.config/pcmanfm/LXDE"
cat <<EOL > "$HOME/.config/pcmanfm/LXDE/pcmanfm.conf"
[Desktop]
theme=Orchis
show-desktop-icons=false  # Disable desktop icons
EOL

# Create a configuration file for Sfwbar
mkdir -p "$HOME/.config/sfwbar"
cat <<EOL > "$HOME/.config/sfwbar/sfwbar.conf"
# Sfwbar configuration
theme = "Orchis"
position = bottom  # Positioning Sfwbar at the bottom
height = 32
icon_size = 24
transparency = 0.8  # Adjust this value for translucency (0.0 to 1.0)

# Add an application launcher for Rofi using the "Everything Button" style
launcher = rofi -show drun -theme /usr/share/rofi/themes/orchis.rasi -font "Fira Code 10"
EOL

# Create a Rofi theme to match Orchis and have transparency
mkdir -p "$HOME/.config/rofi"
cat <<EOL > "$HOME/.config/rofi/orchis.rasi"
configuration {
    modi: "drun";
    background: "rgba(255, 255, 255, 0.8)";  /* Background color with transparency */
    foreground: "#000000";  /* Foreground color */
    border-color: "#3c3c3c"; /* Border color */
}
EOL

# Create a desktop entry for Sfwbar to launch Rofi as an app drawer
cat <<EOL > "$HOME/.local/share/applications/sfwbar-app-drawer.desktop"
[Desktop Entry]
Name=App Drawer
Exec=rofi -show drun -theme $HOME/.config/rofi/orchis.rasi
Terminal=false
Type=Application
EOL

# Create a configuration file for Foot terminal
mkdir -p "$HOME/.config/foot"
cat <<EOL > "$HOME/.config/foot/foot.ini"
[general]
background = rgba(255, 255, 255, 0.9)  # Light background with slight transparency
foreground = #000000  # Text color

[font]
family = "Fira Code"  # Use a programming font
size = 12  # Font size

[scrolling]
scrolling = on

# Other configurations can be added here
EOL

# Notify user of installation completion
echo "PCManFM, Labwc, Sfwbar, and Foot terminal have been configured to use the Orchis theme."
echo "Sfwbar is now positioned at the bottom and themed like the ChromeOS shelf."
echo "Rofi can be accessed via the launcher button in Sfwbar."
echo "Desktop icons have been disabled to resemble ChromeOS."
echo "Please restart Labwc, Sfwbar, and Foot terminal to apply the theme changes."

# Optional: Restart Labwc and Sfwbar (uncomment the following lines if needed)
# killall labwc && labwc &
# killall sfwbar && sfwbar &
