#!/bin/bash

# NVIDIA proprietary driver setup for openSUSE Tumbleweed + Wayland
# Enables dual monitor support with NVIDIA GPU on Wayland

set -e

echo "=== NVIDIA Wayland Setup for openSUSE Tumbleweed ==="
echo ""

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run with root privileges (sudo)"
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

# Step 1: Add NVIDIA repository and install drivers
echo "Step 1: Installing NVIDIA drivers..."
echo ""

if ! zypper lr | grep -q "nvidia"; then
    echo "Adding NVIDIA repository..."
    zypper addrepo --refresh 'https://download.nvidia.com/opensuse/tumbleweed' nvidia
    zypper refresh
fi

echo "Installing NVIDIA driver packages..."
zypper install -y nvidia-compute-utils-G06 nvidia-gl-G06 nvidia-video-G06
zypper install -y nvidia-driver-G06-kmp-default

echo "NVIDIA drivers installed successfully"
echo ""

# Step 2: Configure GRUB for kernel modesetting
echo "Step 2: Configuring GRUB for Wayland support..."
echo ""

GRUB_FILE="/etc/default/grub"
if [ ! -f "$GRUB_FILE" ]; then
    echo "ERROR: $GRUB_FILE not found"
    exit 1
fi

# Backup GRUB config
cp "$GRUB_FILE" "${GRUB_FILE}.backup"
echo "Backup created: ${GRUB_FILE}.backup"

# Remove nomodeset and add nvidia-drm.modeset=1
sed -i 's/nomodeset//g' "$GRUB_FILE"

if grep -q "nvidia-drm.modeset=1" "$GRUB_FILE"; then
    echo "nvidia-drm.modeset=1 already present in GRUB config"
else
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' "$GRUB_FILE"
    echo "Added nvidia-drm.modeset=1 to GRUB config"
fi

# Apply GRUB changes
echo "Applying GRUB configuration..."
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "GRUB configuration updated"
echo ""

# Step 3: Configure dracut for early module loading
echo "Step 3: Configuring early module loading..."
echo ""

DRACUT_DIR="/etc/dracut.conf.d"
DRACUT_CONF="$DRACUT_DIR/nvidia.conf"

mkdir -p "$DRACUT_DIR"

echo 'force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "' > "$DRACUT_CONF"
echo "Created dracut configuration: $DRACUT_CONF"

# Rebuild initramfs
echo "Rebuilding initramfs..."
dracut --force

echo "Initramfs rebuilt successfully"
echo ""

# Summary
echo "=== Setup completed successfully! ==="
echo ""
echo "Next steps:"
echo "  1. Reboot your system: sudo reboot"
echo ""
echo "After reboot, verify the setup:"
echo "  nvidia-smi                                      # Should show your GPU"
echo "  cat /sys/module/nvidia_drm/parameters/modeset  # Should output 'Y'"
echo "  lsmod | grep nvidia                            # Should list nvidia modules"
echo "  kscreen-doctor -o                              # Should list all monitors"
echo ""
echo "Configure monitors in:"
echo "  System Settings -> Display and Monitor -> Display Configuration"
echo ""
echo "Key changes made:"
echo "  - Installed NVIDIA proprietary drivers (G06)"
echo "  - Removed 'nomodeset' from GRUB"
echo "  - Added 'nvidia-drm.modeset=1' to GRUB"
echo "  - Configured early loading of NVIDIA modules"
echo ""
