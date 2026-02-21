#!/bin/bash
## setup command: wget -q "--no-check-certificate" https://raw.githubusercontent.com/Ham-ahmed/Gold/refs/heads/main/install.sh -O - | /bin/sh

######### Only This line to edit with new version ######
version='7.0'
##############################################################

TMPPATH=/tmp/MagicPanelGold
GITHUB_BASE="https://raw.githubusercontent.com/Ham-ahmed/Gold/main"
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

# Function to install package with error handling (silent mode)
install_package() {
    local package=$1
    local package_name=$2

    print_message $BLUE "> Installing $package_name..."

    if [ "$OSTYPE" = "DreamOs" ]; then
        if command_exists apt-get; then
            apt-get update >/dev/null 2>&1 && apt-get install "$package" -y >/dev/null 2>&1
            return $?
        else
            return 1
        fi
    else
        if command_exists opkg; then
            opkg update >/dev/null 2>&1 && opkg install "$package" >/dev/null 2>&1
            return $?
        else
            return 1
        fi
    fi
}

# Function to check package status
check_package() {
    local package=$1
    if [ -f /var/lib/dpkg/status ]; then
        grep -qs "Package: $package" /var/lib/dpkg/status
    elif [ -f /var/lib/opkg/status ]; then
        grep -qs "Package: $package" /var/lib/opkg/status
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
print_message $YELLOW "           MagicPanelGold Auto-Installer"
print_message $CYAN "======================================================"
echo ""

# Detect Python version
PYTHON="PY2"
Packagesix=""
Packagerequests="python-requests"

if command_exists python3; then
    PYTHON="PY3"
    Packagesix="python3-six"
    Packagerequests="python3-requests"
elif command_exists python2; then
    PYTHON="PY2"
    Packagerequests="python-requests"
elif command_exists python; then
    if python --version 2>&1 | grep -q '^Python 3\.'; then
        PYTHON="PY3"
        Packagesix="python3-six"
        Packagerequests="python3-requests"
    else
        PYTHON="PY2"
        Packagerequests="python-requests"
    fi
else
    print_message $RED "> Python not found! Please install Python first."
    exit 1
fi

# Install required packages
echo ""
print_message $BLUE "> Checking required packages..."

if [ "$PYTHON" = "PY3" ] && [ ! -z "$Packagesix" ]; then
    if ! check_package "$Packagesix"; then
        install_package "$Packagesix" "python3-six" >/dev/null 2>&1
    fi
fi

echo ""
if ! check_package "$Packagerequests"; then
    if ! install_package "$Packagerequests" "python-requests" >/dev/null 2>&1; then
        print_message $RED "> Failed to install $Packagerequests"
        exit 1
    fi
fi

echo ""

# Cleanup previous installations
print_message $BLUE "> Cleaning previous installations..."
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

# --- START OF MODIFIED DOWNLOAD SECTION ---
print_message $BLUE "> Downloading from GitHub..."
DOWNLOAD_URL="${GITHUB_BASE}/MagicPanelGold_v${version}.tar.gz"
OUTPUT_FILE="MagicPanelGold_v${version}.tar.gz"

# Function to check if file is a valid gzip archive
is_valid_gz() {
    local file=$1
    # Check the first two bytes for the gzip magic number (0x1f, 0x8b)
    od -A n -t x1 -N 2 "$file" 2>/dev/null | grep -q "1f 8b"
    return $?
}

download_successful=false

# Try downloading with wget first
if command_exists wget; then
    print_message $BLUE "> Attempting download with wget..."
    if wget -q --no-check-certificate --timeout=30 --tries=3 "$DOWNLOAD_URL" -O "$OUTPUT_FILE"; then
        if [ -f "$OUTPUT_FILE" ] && is_valid_gz "$OUTPUT_FILE"; then
            print_message $GREEN "> Download successful with wget (file validated)."
            download_successful=true
        else
            print_message $YELLOW "> wget downloaded file is invalid or corrupted."
            rm -f "$OUTPUT_FILE"
        fi
    else
        print_message $YELLOW "> wget download failed."
    fi
fi

# If wget failed or file invalid, try with curl
if [ "$download_successful" = false ] && command_exists curl; then
    print_message $BLUE "> Attempting download with curl..."
    if curl -s --connect-timeout 10 --max-time 30 -k -L "$DOWNLOAD_URL" -o "$OUTPUT_FILE"; then
        if [ -f "$OUTPUT_FILE" ] && is_valid_gz "$OUTPUT_FILE"; then
            print_message $GREEN "> Download successful with curl (file validated)."
            download_successful=true
        else
            print_message $YELLOW "> curl downloaded file is invalid or corrupted."
            rm -f "$OUTPUT_FILE"
        fi
    else
        print_message $YELLOW "> curl download failed."
    fi
fi

# Check if download was successful
if [ "$download_successful" = false ]; then
    print_message $RED "> Download failed after trying all methods. File may not exist on server."
    print_message $RED "> Please check the version ($version) or your internet connection."
    rm -rf "$TMPPATH"
    exit 1
fi

# Check if file was downloaded (additional check)
if [ ! -f "$OUTPUT_FILE" ]; then
    print_message $RED "> Download file doesn't exist after successful download message!"
    exit 1
fi
# --- END OF MODIFIED DOWNLOAD SECTION ---

# Extract the plugin
print_message $BLUE "> Extracting files..."
if ! tar -xzf "$OUTPUT_FILE" 2>/dev/null; then
    print_message $RED "> Failed to extract files. The archive might be corrupted."
    exit 1
fi

# Install the plugin
print_message $BLUE "> Installing plugin..."

# Look for the plugin files in common directory structures
if [ -d "MagicPanelGold" ]; then
    cp -r "MagicPanelGold"/* "$PLUGINPATH"/../ 2>/dev/null
elif [ -d "MagicPanelGold-main" ]; then
    if [ -d "MagicPanelGold-main/usr" ]; then
        cp -r "MagicPanelGold-main/usr"/* "/usr/" 2>/dev/null
    else
        cp -r "MagicPanelGold-main"/* "$PLUGINPATH"/../ 2>/dev/null
    fi
elif [ -d "usr" ]; then
    cp -r "usr"/* "/usr/" 2>/dev/null
else
    # Create plugin directory and copy files
    mkdir -p "$PLUGINPATH"
    find . -name "*.py" -o -name "*.pyo" -o -name "*.pyc" -o -name "*.so" 2>/dev/null | while read -r file; do
        cp --parents "$file" "$PLUGINPATH"/../ 2>/dev/null
    done
    cp -r --parents "locale" "$PLUGINPATH"/../ 2>/dev/null
fi

# Verify installation
print_message $BLUE "> Verifying installation..."
if [ ! -d "$PLUGINPATH" ]; then
    mkdir -p "$PLUGINPATH"
    find . -name "*.py" -exec cp {} "$PLUGINPATH"/ \; 2>/dev/null
fi

if [ ! -d "$PLUGINPATH" ] || [ -z "$(ls -A "$PLUGINPATH" 2>/dev/null)" ]; then
    print_message $RED "> Installation failed! Plugin directory is empty."
    exit 1
fi

# Set correct permissions
print_message $BLUE "> Setting file permissions..."
find "$PLUGINPATH" -type f -name "*.py" -exec chmod 644 {} \; 2>/dev/null
find "$PLUGINPATH" -type f -name "*.pyo" -exec chmod 644 {} \; 2>/dev/null
find "$PLUGINPATH" -type f -name "*.so" -exec chmod 755 {} \; 2>/dev/null
chmod -R 755 "$PLUGINPATH" 2>/dev/null

# Cleanup
print_message $BLUE "> Cleaning temporary files..."
rm -rf "$TMPPATH" > /dev/null 2>&1
sync

# Success message
echo ""
print_message $CYAN "==================================================================="
print_message $GREEN "===                  Installation Successful!                  ==="
printf "${YELLOW}===                 MagicPanelGold v%-24s===${NC}\n" "$version"
print_message $BLUE "===               Enigma2 restart required                      ==="
print_message $GREEN "===              Downloaded by  >>>>   HAMDY_AHMED             ==="
print_message $CYAN "==================================================================="

sleep 3

# Automatic restart without asking
echo ""
print_message $YELLOW "========================================================="
print_message $YELLOW "===         Automatic restart in 3 seconds            ==="
print_message $YELLOW "========================================================="
sleep 3

print_message $GREEN "=== Starting automatic restart ==="

# Restart enigma2 automatically
if command_exists systemctl; then
    systemctl restart enigma2
elif command_exists restartGUI; then
    restartGUI
else
    killall -9 enigma2
    sleep 1
    # Check if enigma2 is actually running before trying to start it again in background
    if ! pgrep -x "enigma2" > /dev/null; then
        enigma2 >/dev/null 2>&1 &
    fi
fi

exit 0