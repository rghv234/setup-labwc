#!/bin/sh

# Install necessary dependencies
apk update
apk add \
    greetd \
    labwc \
    rust \
    cargo \
    wlroots \
    make \
    musl-dev \
    git \
    rustup

# Set up Rust
rustup toolchain install stable
rustup default stable

# Clone and build tuigreet
git clone https://github.com/apognu/tuigreet
cd tuigreet
cargo build --release
sudo mv target/release/tuigreet /usr/local/bin/tuigreet

# Create cache directory for tuigreet
sudo mkdir /var/cache/tuigreet
sudo chown greeter:greeter /var/cache/tuigreet
sudo chmod 0755 /var/cache/tuigreet

# Create the greeter user
sudo useradd -M -G video greeter
sudo chown -R greeter:greeter /etc/greetd/

# Configure greetd
sudo tee /etc/greetd/config.toml <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd labwc"
user = "greeter"
EOF

# Create the OpenRC service script
cat << 'EOF' | sudo tee /etc/init.d/greetd > /dev/null
#!/sbin/openrc-run

name="$RC_SVCNAME"
command=/usr/local/bin/greetd
pidfile="/var/run/$RC_SVCNAME.pid"
command_background="yes"

stop() {
    kill `cat /var/run/$RC_SVCNAME.pid`
}
EOF

# Make the script executable and add it to OpenRC
sudo chmod +x /etc/init.d/greetd
sudo rc-update add greetd

# Enable and start greetd
sudo rc-service greetd start
