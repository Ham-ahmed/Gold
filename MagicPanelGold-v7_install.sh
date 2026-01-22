#!/bin/bash
##setup command=wget -q "--no-check-certificate" https://raw.githubusercontent.com/Ham-ahmed/Gold/refs/heads/main/MagicPanelGold_v7.0.sh -O - | /bin/sh

######### Only This line to edit with new version ######
version='6.5.2'
##############################################################

TMPPATH=/tmp/MagicPanelGold
GITHUB_BASE="https://raw.githubusercontent.com/Ham-ahmed/Gold/refs/heads/main"
GITHUB_RAW="${GITHUB_BASE}"

# Check architecture and set plugin path
if [ ! -d /usr/lib64 ]; then
    PLUGINPATH="/usr/lib/enigma2/python/Plugins/Extensions/MagicPanelGold"
else
    PLUGINPATH="/usr/lib64/enigma2/python/Plugins/Extensions/MagicPanelGold"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;34m'
BLUE='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check for updates
check_for_updates() {
    print_message $BLUE "> Checking for updates..."
    
    # Try multiple methods to get latest version
    LATEST_VERSION=$(wget -q --timeout=10 --tries=2 -O - "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r' | tr -d ' ' | grep -E '^[0-9.]+$')
    
    if [ -z "$LATEST_VERSION" ]; then
        print_message $YELLOW "> Could not check for updates. Continuing installation..."
        return 1
    fi
    
    if [ "$version" != "$LATEST_VERSION" ]; then
        echo ""
        print_message $GREEN "####################################################"
        print_message $BLUE "#              NEW VERSION AVAILABLE                #"
        printf "${YELLOW}#       Current version: %-23s#${NC}\n" "$version        "
        printf "${BLUE}#       Latest version: %-24s#${NC}\n" "$LATEST_VERSION    "     
        print_message $YELLOW "#    Please download the latest version from:     #"
        print_message $BLUE "#   https://github.com/Ham-ahmed/magic/tree/main    #"
        print_message $GREEN "####################################################"
        echo ""
        print_message $YELLOW "> Press Ctrl+C to cancel and download the latest version"
        print_message $YELLOW "> Continuing with current version in 10 seconds..."
        sleep 10
        return 0
    else
        print_message $GREEN "> You have the latest version ($version)"
        return 1
    fi
}

# Function to install package with error handling
install_package() {
    local package=$1
    local package_name=$2
    
    print_message $BLUE "> Installing $package_name..."
    
    if [ "$OSTYPE" = "DreamOs" ]; then
        if command_exists apt-get; then
            apt-get update && apt-get install "$package" -y
        else
            print_message $RED "> apt-get not found!"
            return 1
        fi
    else
        if command_exists opkg; then
            opkg update && opkg install "$package"
        else
            print_message $RED "> opkg not found!"
            return 1
        fi
    fi
    
    return $?
}

# Function to check package status
check_package() {
    local package=$1
    if [ -f /var/lib/dpkg/status ]; then
        grep -qs "Package: $package" /var/lib/dpkg/status
    else
        grep -qs "Package: $package" /var/lib/opkg/status
    fi
}

# Detect OS type and package manager status
if [ -f /var/lib/dpkg/status ]; then
    STATUS="/var/lib/dpkg/status"
    OSTYPE="DreamOs"
else
    STATUS="/var/lib/opkg/status"
    OSTYPE="Dream"
fi

echo ""
# Detect Python version
if command_exists python; then
    if python --version 2>&1 | grep -q '^Python 3\.'; then
        print_message $GREEN "You have Python3 image"
        PYTHON="PY3"
        Packagesix="python3-six"
        Packagerequests="python3-requests"
    else
        print_message $GREEN "You have Python2 image"
        PYTHON="PY2"
        Packagerequests="python-requests"
    fi
else
    print_message $RED "Python not found! Please install Python first."
    exit 1
fi

# Install required packages
echo ""
if [ "$PYTHON" = "PY3" ] && [ "$Packagesix" != "" ]; then
    if ! check_package "$Packagesix"; then
        print_message $YELLOW "> Required package $Packagesix not found, installing..."
        if ! install_package "$Packagesix" "python3-six"; then
            print_message $RED "> Failed to install $Packagesix"
            exit 1
        fi
    fi
fi

echo ""
if ! check_package "$Packagerequests"; then
    print_message $YELLOW "> Need to install $Packagerequests"
    if ! install_package "$Packagerequests" "python-requests"; then
        print_message $RED "> Failed to install $Packagerequests"
        exit 1
    fi
fi

echo ""

# Check for updates before proceeding
check_for_updates

# Cleanup previous installations
print_message $BLUE "> Cleaning up previous installations..."
[ -d "$TMPPATH" ] && rm -rf "$TMPPATH" > /dev/null 2>&1
[ -d "$PLUGINPATH" ] && rm -rf "$PLUGINPATH" > /dev/null 2>&1

# Download and install plugin
print_message $BLUE "> Downloading MagicPanelGold v$version..."
mkdir -p "$TMPPATH"
cd "$TMPPATH" || exit 1

# Detect OE version
if [ -f /var/lib/dpkg/status ]; then
    print_message $GREEN "# Your image is OE2.5/2.6 #"
else
    print_message $GREEN "# Your image is OE2.0 #"
fi

echo ""

# Download the plugin
if ! wget -q "--no-check-certificate" "${GITHUB_BASE}/MagicPanelGold_v7.0.tar.gz"; then
    print_message $RED "> Download failed!"
    exit 1
fi

# Extract the plugin
print_message $BLUE "> Extracting plugin..."
if ! tar -xzf "MagicPanelGold_v7.0.tar.gz"; then
    print_message $RED "> Extraction failed!"
    exit 1
fi

# Install the plugin
print_message $BLUE "> Installing plugin..."
if [ -d "MagicPanelGold-main/usr" ]; then
    cp -r "MagicPanelGold-main/usr" "/"
else
    print_message $RED "> Plugin directory structure incorrect!"
    exit 1
fi

# Verify installation
print_message $BLUE "> Verifying installation..."
if [ ! -d "$PLUGINPATH" ]; then
    print_message $RED "> Installation failed! Plugin not found in expected location."
    exit 1
fi

# Cleanup
print_message $BLUE "> Cleaning up temporary files..."
rm -rf "$TMPPATH" > /dev/null 2>&1
sync

# Success message
echo ""
print_message $YELLOW "==================================================================="
print_message $BLUE "===                    INSTALLED SUCCESSFULLY                     ==="
printf "${GREEN}===                 MagicPanelGold v%-24s===${NC}\n" "$version"
print_message $BLUE "===                Enigma2 restart is required                    ==="
print_message $GREEN "===              UPLOADED BY  >>>>   HAMDY_AHMED                 ==="
print_message $YELLOW "==================================================================="

sleep 2
print_message $GREEN "==================================================================="
print_message $YELLOW "===                        Restarting                          ==="
print_message $GREEN "==================================================================="

sleep 5
# Restart enigma2
if command_exists systemctl; then
    systemctl restart enigma2
else
    killall -9 enigma2
fi

exit 0
