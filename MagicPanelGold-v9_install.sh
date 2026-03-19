#!/bin/bash

##setup command=wget -q "--no-check-certificate" https://raw.githubusercontent.com/Ham-ahmed/Gold/refs/heads/main/install.sh -O - | /bin/sh

######### Only This line to edit with new version ######
version='8.0'
##############################################################

TMPPATH=/tmp/MagicPanelGold
GITHUB_BASE="https://raw.githubusercontent.com/Ham-ahmed/Gold/refs/heads/main"
GITHUB_RAW="${GITHUB_BASE}"

# Check architecture and set plugin path
if [ -d /usr/lib64 ]; then
    PLUGINPATH="/usr/lib64/enigma2/python/Plugins/Extensions/MagicPanelGold"
else
    PLUGINPATH="/usr/lib/enigma2/python/Plugins/Extensions/MagicPanelGold"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

# Function to restart Enigma2
restart_enigma2() {
    print_message $YELLOW "> Restarting Enigma2..."
    sleep 2
    
    # Try different methods to restart enigma2
    if command_exists systemctl; then
        systemctl restart enigma2
    elif command_exists init; then
        init 4
        sleep 2
        init 3
    elif command_exists killall; then
        killall -9 enigma2
        sleep 2
        if command_exists enigma2; then
            enigma2 >/dev/null 2>&1 &
        fi
    else
        print_message $RED "> Could not restart Enigma2 automatically"
        print_message $YELLOW "> Please restart Enigma2 manually"
    fi
    
    # Wait a moment to ensure restart starts
    sleep 3
}

# Function to check for updates
check_for_updates() {
    print_message $BLUE "> Checking for updates..."
    
    # Try multiple methods to get latest version
    LATEST_VERSION=""
    
    if command_exists wget; then
        LATEST_VERSION=$(wget -q --timeout=10 --tries=2 --no-check-certificate -O - "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r' | tr -d ' ')
    fi
    
    if [ -z "$LATEST_VERSION" ] && command_exists curl; then
        LATEST_VERSION=$(curl -s --connect-timeout 5 --max-time 10 "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r' | tr -d ' ')
    fi
    
    # Validate version format
    if [ -n "$LATEST_VERSION" ] && [[ "$LATEST_VERSION" =~ ^[0-9.]+$ ]]; then
        # Compare versions
        if [ "$version" != "$LATEST_VERSION" ]; then
            echo ""
            print_message $GREEN "####################################################"
            print_message $BLUE "#              New version available!               #"
            printf "${YELLOW}#       Current version: %-23s#${NC}\n" "$version        "
            printf "${BLUE}#       Latest version: %-23s#${NC}\n" "$LATEST_VERSION"     
            print_message $YELLOW "#    Please download latest version from:         #"
            print_message $BLUE "#      https://github.com/Ham-ahmed/Gold            #"
            print_message $GREEN "####################################################"
            echo ""
            print_message $YELLOW "> Press Ctrl+C to cancel and download latest version"
            print_message $YELLOW "> Continuing with current version in 10 seconds..."
            sleep 10
            return 0
        else
            print_message $GREEN "> You have the latest version ($version)"
            return 1
        fi
    else
        print_message $YELLOW "> Cannot check for updates. Proceeding with installation..."
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
            apt-get update >/dev/null 2>&1
            apt-get install "$package" -y >/dev/null 2>&1
            return $?
        else
            print_message $RED "> apt-get not found!"
            return 1
        fi
    else
        if command_exists opkg; then
            opkg update >/dev/null 2>&1
            opkg install "$package" >/dev/null 2>&1
            return $?
        else
            print_message $RED "> opkg not found!"
            return 1
        fi
    fi
}

# Function to check package status
check_package() {
    local package=$1
    if [ -f /var/lib/dpkg/status ]; then
        grep -qs "Package: $package" /var/lib/dpkg/status
        return $?
    elif [ -f /var/lib/opkg/status ]; then
        grep -qs "Package: $package" /var/lib/opkg/status
        return $?
    else
        return 1
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

# Clear screen and show banner
clear
echo ""
print_message $CYAN "======================================================"
print_message $YELLOW "           MagicPanelGold Installer v$version"
print_message $CYAN "======================================================"
echo ""

# Detect Python version
PYTHON="PY2"
Packagesix=""
Packagerequests="python-requests"

if command_exists python3; then
    print_message $GREEN "> You have Python3 image"
    PYTHON="PY3"
    Packagesix="python3-six"
    Packagerequests="python3-requests"
elif command_exists python2; then
    print_message $GREEN "> You have Python2 image"
    PYTHON="PY2"
    Packagerequests="python-requests"
elif command_exists python; then
    if python --version 2>&1 | grep -q '^Python 3\.'; then
        print_message $GREEN "> You have Python3 image"
        PYTHON="PY3"
        Packagesix="python3-six"
        Packagerequests="python3-requests"
    else
        print_message $GREEN "> You have Python2 image"
        PYTHON="PY2"
        Packagerequests="python-requests"
    fi
else
    print_message $RED "> Python not found! Please install Python first."
    exit 1
fi

# Check for updates before proceeding
check_for_updates

# Install required packages
echo ""
print_message $BLUE "> Checking required packages..."

if [ "$PYTHON" = "PY3" ] && [ -n "$Packagesix" ]; then
    if ! check_package "$Packagesix"; then
        print_message $YELLOW "> Required package $Packagesix not found, installing..."
        install_package "$Packagesix" "python3-six"
    fi
fi

echo ""
if ! check_package "$Packagerequests"; then
    print_message $YELLOW "> $Packagerequests not found, installing..."
    if ! install_package "$Packagerequests" "python-requests"; then
        print_message $RED "> Failed to install $Packagerequests"
        print_message $YELLOW "> Continuing without it, plugin might not work properly..."
    fi
fi

echo ""

# Cleanup previous installations
print_message $BLUE "> Cleaning previous installations..."
rm -rf "$TMPPATH" > /dev/null 2>&1
rm -rf "$PLUGINPATH" > /dev/null 2>&1

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
print_message $BLUE "> Downloading..."
DOWNLOAD_URL="${GITHUB_BASE}/MagicPanelGold_v${version}.tar.gz"

# Try primary download with wget
if command_exists wget; then
    if ! wget -q --no-check-certificate --timeout=20 --tries=2 "$DOWNLOAD_URL" -O "MagicPanelGold_v${version}.tar.gz"; then
        print_message $YELLOW "> Primary download failed, trying alternate method..."
        DOWNLOAD_FAILED=1
    else
        DOWNLOAD_FAILED=0
    fi
elif command_exists curl; then
    if ! curl -s -k --connect-timeout 20 --max-time 30 "$DOWNLOAD_URL" -o "MagicPanelGold_v${version}.tar.gz"; then
        print_message $YELLOW "> Primary download failed, trying alternate method..."
        DOWNLOAD_FAILED=1
    else
        DOWNLOAD_FAILED=0
    fi
else
    print_message $RED "> Neither wget nor curl found!"
    exit 1
fi

# Try alternate URL if primary failed
if [ "$DOWNLOAD_FAILED" = "1" ]; then
    ALTERNATE_URL="https://github.com/Ham-ahmed/Gold/raw/main/MagicPanelGold_v${version}.tar.gz"
    print_message $YELLOW "> Trying alternate URL..."
    
    if command_exists wget; then
        if ! wget -q --no-check-certificate --timeout=20 --tries=2 "$ALTERNATE_URL" -O "MagicPanelGold_v${version}.tar.gz"; then
            print_message $RED "> Complete download failure!"
            exit 1
        fi
    elif command_exists curl; then
        if ! curl -s -k --connect-timeout 20 --max-time 30 "$ALTERNATE_URL" -o "MagicPanelGold_v${version}.tar.gz"; then
            print_message $RED "> Complete download failure!"
            exit 1
        fi
    fi
fi

# Check if file was downloaded
if [ ! -f "MagicPanelGold_v${version}.tar.gz" ] || [ ! -s "MagicPanelGold_v${version}.tar.gz" ]; then
    print_message $RED "> Download file doesn't exist or is empty!"
    exit 1
fi

# Extract the plugin
print_message $BLUE "> Extracting files..."
if ! tar -xzf "MagicPanelGold_v${version}.tar.gz" 2>/dev/null; then
    print_message $RED "> Failed to extract files!"
    exit 1
fi

# Install the plugin
print_message $BLUE "> Installing plugin..."

# Create plugin directory
mkdir -p "$PLUGINPATH"

# Look for the plugin files in common directory structures
if [ -d "MagicPanelGold" ]; then
    cp -rf "MagicPanelGold"/* "$PLUGINPATH"/ 2>/dev/null
elif [ -d "MagicPanelGold-main" ]; then
    if [ -d "MagicPanelGold-main/usr" ]; then
        cp -rf "MagicPanelGold-main/usr"/* "/usr/" 2>/dev/null
    else
        cp -rf "MagicPanelGold-main"/* "$PLUGINPATH"/ 2>/dev/null
    fi
elif [ -d "usr" ]; then
    cp -rf "usr"/* "/usr/" 2>/dev/null
else
    # Copy all files to plugin directory
    cp -rf ./* "$PLUGINPATH"/ 2>/dev/null
fi

# Verify installation
print_message $BLUE "> Verifying installation..."

if [ ! -d "$PLUGINPATH" ] || [ -z "$(ls -A "$PLUGINPATH" 2>/dev/null)" ]; then
    print_message $RED "> Installation failed! Could not copy plugin files."
    exit 1
fi

# Count installed files
file_count=$(find "$PLUGINPATH" -type f 2>/dev/null | wc -l)
print_message $GREEN "> Successfully installed $file_count files"

# Set correct permissions
print_message $BLUE "> Setting file permissions..."
find "$PLUGINPATH" -type f -name "*.py" -exec chmod 644 {} \; 2>/dev/null
find "$PLUGINPATH" -type f -name "*.pyo" -exec chmod 644 {} \; 2>/dev/null
find "$PLUGINPATH" -type f -name "*.so" -exec chmod 755 {} \; 2>/dev/null
find "$PLUGINPATH" -type d -exec chmod 755 {} \; 2>/dev/null
chmod -R 755 "$PLUGINPATH" 2>/dev/null

# Cleanup
print_message $BLUE "> Cleaning temporary files..."
rm -rf "$TMPPATH" > /dev/null 2>&1
sync

# Success message
echo ""
print_message $CYAN "==================================================================="
print_message $GREEN "===              Installation Successful!                       ==="
printf "${YELLOW}===                 MagicPanelGold v%-24s===${NC}\n" "$version"
print_message $BLUE "===              Downloaded by  >>>>   HAMDY_AHMED               ==="
print_message $CYAN "==================================================================="
echo ""
print_message $YELLOW "Enigma2 will restart automatically after 5 seconds..."
print_message $BLUE "Press Ctrl+C to cancel"
echo ""

# Countdown before restart
for i in {5..1}; do
    printf "${YELLOW}Restarting in $i seconds...${NC}\r"
    sleep 1
done
echo ""

# Automatic restart
print_message $GREEN "========================================================="
print_message $YELLOW "===            Restarting Enigma2                     ==="
print_message $GREEN "========================================================="

# Call restart function
restart_enigma2

exit 0