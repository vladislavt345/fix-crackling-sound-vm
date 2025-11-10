#!/bin/bash

# asusctl installation script for openSUSE Tumbleweed
# Provides control for ASUS laptop features (performance profiles, keyboard backlight, battery management)

set -e

echo "=== asusctl Setup for openSUSE Tumbleweed ==="
echo ""

# Check for root privileges
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: This script should NOT be run as root"
   echo "Run it as a regular user. It will prompt for sudo when needed."
   exit 1
fi

# Check if running openSUSE
if ! grep -q "openSUSE" /etc/os-release 2>/dev/null; then
    echo "WARNING: This script is designed for openSUSE Tumbleweed"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Install dependencies
echo "Step 1: Installing dependencies..."
echo ""

sudo zypper install -y git make cmake gcc gcc-c++ rust cargo
sudo zypper install -y pkg-config libusb-1_0-devel systemd-devel
sudo zypper install -y gtk3-devel glib2-devel boost-devel
sudo zypper install -y pciutils-devel libdrm-devel
sudo zypper install -y clang clang-devel libclang13

echo "Dependencies installed successfully"
echo ""

# Step 2: Create directory and install supergfxctl
echo "Step 2: Installing supergfxctl..."
echo ""

mkdir -p ~/Asus
cd ~/Asus

if [ -d "supergfxctl" ]; then
    echo "Removing existing supergfxctl directory..."
    rm -rf supergfxctl
fi

git clone https://gitlab.com/asus-linux/supergfxctl.git
cd supergfxctl
make
sudo make install

echo "supergfxctl installed successfully"
echo ""

# Step 3: Install asusctl
echo "Step 3: Installing asusctl..."
echo ""

cd ~/Asus

if [ -d "asusctl" ]; then
    echo "Removing existing asusctl directory..."
    rm -rf asusctl
fi

git clone https://gitlab.com/asus-linux/asusctl.git
cd asusctl
export LIBCLANG_PATH=/usr/lib64
make
sudo make install

echo "asusctl installed successfully"
echo ""

# Step 4: Create group and configure permissions
echo "Step 4: Configuring user permissions..."
echo ""

if ! getent group asus > /dev/null 2>&1; then
    sudo groupadd asus
    echo "Created 'asus' group"
else
    echo "'asus' group already exists"
fi

sudo usermod -a -G asus $USER
echo "Added user $USER to 'asus' group"
echo ""

# Step 5: Configure D-Bus
echo "Step 5: Configuring D-Bus..."
echo ""

DBUS_CONF="/usr/share/dbus-1/system.d/asusd.conf"
sudo mkdir -p /usr/share/dbus-1/system.d/

sudo tee "$DBUS_CONF" > /dev/null << 'EOF'
<!DOCTYPE busconfig PUBLIC
          "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
          "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
    <policy user="root">
        <allow own="xyz.ljones.Asusd"/>
    </policy>
    <policy group="asus">
        <allow send_destination="xyz.ljones.Asusd"/>
        <allow receive_sender="xyz.ljones.Asusd"/>
    </policy>
</busconfig>
EOF

echo "D-Bus configuration created: $DBUS_CONF"
echo ""

# Step 6: Start and enable services
echo "Step 6: Starting services..."
echo ""

sudo systemctl daemon-reload
sudo systemctl enable asusd
sudo systemctl start asusd

# Note: User service will be available after relogin
echo "System service enabled and started"
echo ""

# Step 7: Verify installation
echo "Step 7: Verifying installation..."
echo ""

if sudo systemctl is-active --quiet asusd; then
    echo "Service status: RUNNING"
else
    echo "WARNING: Service is not running"
fi

if command -v asusctl &> /dev/null; then
    echo "asusctl version: $(asusctl --version)"
else
    echo "WARNING: asusctl command not found in PATH"
fi

echo ""

# Summary
echo "=== Setup completed! ==="
echo ""
echo "IMPORTANT: You must log out and log back in for group changes to take effect."
echo ""
echo "After relogin, start the user service:"
echo "  systemctl --user enable asusd-user"
echo "  systemctl --user start asusd-user"
echo ""
echo "Basic commands:"
echo ""
echo "Performance profiles:"
echo "  asusctl profile -P Performance    # Maximum performance"
echo "  asusctl profile -P Balanced       # Balanced mode"
echo "  asusctl profile -P Quiet          # Quiet mode"
echo "  asusctl profile -p                # Show current profile"
echo ""
echo "Keyboard backlight:"
echo "  asusctl -k high                   # High brightness"
echo "  asusctl -k med                    # Medium brightness"
echo "  asusctl -k low                    # Low brightness"
echo "  asusctl -k off                    # Turn off"
echo ""
echo "Battery management:"
echo "  asusctl -c 80                     # Set charge limit to 80%"
echo "  asusctl -o                        # One-time charge to 100%"
echo ""
echo "GUI control center:"
echo "  rog-control-center"
echo ""
echo "To verify services after relogin:"
echo "  systemctl status asusd"
echo "  systemctl --user status asusd-user"
echo ""
