    #!/bin/bash

    # Video Sound Fix Script for openSUSE Tumbleweed
    # Fixes H.264 codec issues by installing FFmpeg with proper codecs from Packman

    set -e  # Exit on error

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    # Function to print colored messages
    print_step() {
        echo -e "${GREEN}[STEP]${NC} $1"
    }

    print_info() {
        echo -e "${YELLOW}[INFO]${NC} $1"
    }

    print_error() {
        echo -e "${RED}[ERROR]${NC} $1"
    }

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root. It will ask for sudo when needed."
        exit 1
    fi

    echo "=========================================="
    echo "Video Sound Fix for openSUSE Tumbleweed"
    echo "=========================================="
    echo ""

    # Step 1: Install FFmpeg
    print_step "Installing FFmpeg-7..."
    sudo zypper install -y ffmpeg-7
    echo ""

    # Step 2: Add Packman repository
    print_step "Adding Packman repository (with codecs)..."
    print_info "Packman provides H.264 codec support that's disabled by default in openSUSE"
    sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
    echo ""

    # Step 3: Refresh repositories
    print_step "Refreshing repositories..."
    sudo zypper refresh
    echo ""

    # Step 4: Switch to Packman versions with H.264 support
    print_step "Switching to Packman versions with H.264 codec..."
    print_info "This will change vendor for multimedia packages"
    sudo zypper dup --from packman --allow-vendor-change -y
    echo ""

    # Step 5: Verify H.264 decoder
    print_step "Verifying H.264 decoder installation..."
    if ffmpeg -decoders | grep -q h264; then
        print_info "H.264 decoder is available:"
        ffmpeg -decoders | grep h264
    else
        print_error "H.264 decoder not found. Something went wrong."
        exit 1
    fi
    echo ""

    # Step 6: Firefox configuration
    print_step "Firefox configuration required..."
    echo ""
    echo "Please manually configure Firefox by:"
    echo "1. Open Firefox and type 'about:config' in the address bar"
    echo "2. Accept the warning if prompted"
    echo "3. Search for and set these preferences:"
    echo "   - media.ffmpeg.enabled = true"
    echo "   - media.ffvpx.enabled = false"
    echo "   - media.rdd-ffmpeg.enabled = true"
    echo ""
    read -p "Press Enter after you've configured Firefox..."

    # Step 7: Restart Firefox
    print_step "Restarting Firefox..."
    if pgrep -x "firefox" > /dev/null; then
        print_info "Closing Firefox..."
        killall firefox
        sleep 2
    fi
    print_info "Starting Firefox..."
    firefox &
    echo ""

    print_step "Setup complete!"
    echo ""
    echo "=========================================="
    echo "Why this was necessary:"
    echo "openSUSE disables H.264 decoder by default due to patent concerns."
    echo "Packman repository provides the full version with codecs enabled."
    echo "=========================================="
