#!/bin/bash

##setup command=wget -q "--no-check-certificate" https://raw.githubusercontent.com/Ham-ahmed/Gold/refs/heads/main/install.sh -O - | /bin/sh

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

# Function to check for updates
check_for_updates() {
    print_message $BLUE "> التحقق من وجود تحديثات..."
    
    # Try multiple methods to get latest version
    LATEST_VERSION=$(wget -q --timeout=20 --tries=3 --no-check-certificate -O - "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r' | tr -d ' ' | grep -E '^[0-9.]+$')
    
    if [ -z "$LATEST_VERSION" ]; then
        LATEST_VERSION=$(curl -s --connect-timeout 10 --max-time 15 "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r' | tr -d ' ' | grep -E '^[0-9.]+$')
    fi
    
    if [ -z "$LATEST_VERSION" ]; then
        print_message $YELLOW "> لا يمكن التحقق من التحديثات. المتابعة بالتثبيت..."
        return 1
    fi
    
    # Compare versions
    if [ "$version" != "$LATEST_VERSION" ]; then
        echo ""
        print_message $GREEN "####################################################"
        print_message $BLUE "#              نسخة جديدة متوفرة!                 #"
        printf "${YELLOW}#       النسخة الحالية: %-23s#${NC}\n" "$version        "
        printf "${BLUE}#       أحدث نسخة: %-27s#${NC}\n" "$LATEST_VERSION    "     
        print_message $YELLOW "#    يرجى تحميل أحدث نسخة من:                  #"
        print_message $BLUE "#   https://github.com/Ham-ahmed/Gold            #"
        print_message $GREEN "####################################################"
        echo ""
        print_message $YELLOW "> اضغط Ctrl+C للإلغاء وتحميل أحدث نسخة"
        print_message $YELLOW "> المتابعة بالنسخة الحالية خلال 10 ثواني..."
        sleep 10
        return 0
    else
        print_message $GREEN "> لديك أحدث نسخة ($version)"
        return 1
    fi
}

# Function to install package with error handling
install_package() {
    local package=$1
    local package_name=$2
    
    print_message $BLUE "> تثبيت $package_name..."
    
    if [ "$OSTYPE" = "DreamOs" ]; then
        if command_exists apt-get; then
            apt-get update >/dev/null 2>&1 && apt-get install "$package" -y >/dev/null 2>&1
            return $?
        else
            print_message $RED "> لم يتم العثور على apt-get!"
            return 1
        fi
    else
        if command_exists opkg; then
            opkg update >/dev/null 2>&1 && opkg install "$package" >/dev/null 2>&1
            return $?
        else
            print_message $RED "> لم يتم العثور على opkg!"
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
print_message $YELLOW "           MagicPanelGold Installer v$version"
print_message $CYAN "======================================================"
echo ""

# Detect Python version
PYTHON="PY2"
Packagesix=""
Packagerequests="python-requests"

if command_exists python3; then
    print_message $GREEN "> لديك صورة Python3"
    PYTHON="PY3"
    Packagesix="python3-six"
    Packagerequests="python3-requests"
elif command_exists python2; then
    print_message $GREEN "> لديك صورة Python2"
    PYTHON="PY2"
    Packagerequests="python-requests"
elif command_exists python; then
    if python --version 2>&1 | grep -q '^Python 3\.'; then
        print_message $GREEN "> لديك صورة Python3"
        PYTHON="PY3"
        Packagesix="python3-six"
        Packagerequests="python3-requests"
    else
        print_message $GREEN "> لديك صورة Python2"
        PYTHON="PY2"
        Packagerequests="python-requests"
    fi
else
    print_message $RED "> لم يتم العثور على Python! يرجى تثبيت Python أولاً."
    exit 1
fi

# Check for updates before proceeding
check_for_updates

# Install required packages
echo ""
print_message $BLUE "> التحقق من الحزم المطلوبة..."

if [ "$PYTHON" = "PY3" ] && [ ! -z "$Packagesix" ]; then
    if ! check_package "$Packagesix"; then
        print_message $YELLOW "> الحزمة المطلوبة $Packagesix غير موجودة، جاري التثبيت..."
        if ! install_package "$Packagesix" "python3-six"; then
            print_message $YELLOW "> فشل تثبيت $Packagesix، المتابعة بدونها..."
        fi
    fi
fi

echo ""
if ! check_package "$Packagerequests"; then
    print_message $YELLOW "> يجب تثبيت $Packagerequests"
    if ! install_package "$Packagerequests" "python-requests"; then
        print_message $RED "> فشل تثبيت $Packagerequests"
        exit 1
    fi
fi

echo ""

# Cleanup previous installations
print_message $BLUE "> تنظيف التثبيتات السابقة..."
[ -d "$TMPPATH" ] && rm -rf "$TMPPATH" > /dev/null 2>&1
[ -d "$PLUGINPATH" ] && rm -rf "$PLUGINPATH" > /dev/null 2>&1

# Download and install plugin
print_message $BLUE "> تحميل MagicPanelGold v$version..."
mkdir -p "$TMPPATH"
cd "$TMPPATH" || exit 1

# Detect OE version
if [ -f /var/lib/dpkg/status ]; then
    print_message $GREEN "# صورتك هي OE2.5/2.6 #"
else
    print_message $GREEN "# صورتك هي OE2.0 #"
fi

echo ""

# Download the plugin
print_message $BLUE "> جاري التحميل..."
DOWNLOAD_URL="${GITHUB_BASE}/MagicPanelGold_v${version}.tar.gz"
if ! wget -q --no-check-certificate --timeout=30 --tries=3 "$DOWNLOAD_URL" -O "MagicPanelGold_v${version}.tar.gz"; then
    print_message $RED "> فشل التحميل من: $DOWNLOAD_URL"
    # Try alternative URL
    ALTERNATE_URL="https://github.com/Ham-ahmed/Gold/raw/main/MagicPanelGold_v${version}.tar.gz"
    print_message $YELLOW "> المحاولة من رابط بديل..."
    if ! wget -q --no-check-certificate --timeout=30 --tries=2 "$ALTERNATE_URL" -O "MagicPanelGold_v${version}.tar.gz"; then
        print_message $RED "> فشل التحميل تماماً!"
        exit 1
    fi
fi

# Check if file was downloaded
if [ ! -f "MagicPanelGold_v${version}.tar.gz" ]; then
    print_message $RED "> ملف التحميل غير موجود!"
    exit 1
fi

# Extract the plugin
print_message $BLUE "> استخراج الملفات..."
if ! tar -xzf "MagicPanelGold_v${version}.tar.gz" 2>/dev/null; then
    print_message $RED "> فشل استخراج الملفات!"
    exit 1
fi

# Install the plugin
print_message $BLUE "> تثبيت الإضافة..."

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
    find . -name "*.py" -o -name "*.pyo" -o -name "*.pyc" -o -name "*.so" | while read -r file; do
        cp --parents "$file" "$PLUGINPATH"/../ 2>/dev/null
    done
    cp -r --parents "locale" "$PLUGINPATH"/../ 2>/dev/null
fi

# Verify installation
print_message $BLUE "> التحقق من التثبيت..."
if [ ! -d "$PLUGINPATH" ]; then
    # Try to create the plugin directory manually
    mkdir -p "$PLUGINPATH"
    # Copy any Python files to the plugin directory
    find . -name "*.py" -exec cp {} "$PLUGINPATH"/ \; 2>/dev/null
fi

if [ ! -d "$PLUGINPATH" ] || [ -z "$(ls -A "$PLUGINPATH" 2>/dev/null)" ]; then
    print_message $RED "> فشل التثبيت! الإضافة غير موجودة في الموقع المتوقع."
    exit 1
fi

# Set correct permissions
print_message $BLUE "> ضبط صلاحيات الملفات..."
find "$PLUGINPATH" -type f -name "*.py" -exec chmod 644 {} \; 2>/dev/null
find "$PLUGINPATH" -type f -name "*.pyo" -exec chmod 644 {} \; 2>/dev/null
find "$PLUGINPATH" -type f -name "*.so" -exec chmod 755 {} \; 2>/dev/null
chmod -R 755 "$PLUGINPATH" 2>/dev/null

# Cleanup
print_message $BLUE "> تنظيف الملفات المؤقتة..."
rm -rf "$TMPPATH" > /dev/null 2>&1
sync

# Success message
echo ""
print_message $CYAN "==================================================================="
print_message $GREEN "===                    تم التثبيت بنجاح!                     ==="
printf "${YELLOW}===                 MagicPanelGold v%-24s===${NC}\n" "$version"
print_message $BLUE "===               يلزم إعادة تشغيل الإنيجماتوو                  ==="
print_message $GREEN "===              تم التحميل بواسطة  >>>>   HAMDY_AHMED         ==="
print_message $CYAN "==================================================================="

sleep 3

# Ask user if they want to restart
echo ""
print_message $YELLOW "هل تريد إعادة تشغيل الإنيجماتوو الآن؟ (y/n)"
read -t 30 -n 1 -p "> " restart_answer
echo ""

if [[ "$restart_answer" =~ ^[Yy]$ ]] || [ -z "$restart_answer" ]; then
    print_message $GREEN "================================================="
    print_message $YELLOW "===           جاري إعادة التشغيل             ==="
    print_message $GREEN "================================================="
    
    sleep 2
    
    # Restart enigma2
    if command_exists systemctl; then
        systemctl restart enigma2
    elif command_exists restartGUI; then
        restartGUI
    else
        killall -9 enigma2
        sleep 1
        enigma2 >/dev/null 2>&1 &
    fi
else
    print_message $YELLOW "سيتوجب إعادة تشغيل الجهاز يدوياً لتشغيل الإضافة."
fi

echo ""
print_message $GREEN "======================================================"
print_message $YELLOW "       تم الانتهاء من تثبيت MagicPanelGold"
print_message $GREEN "======================================================"
echo ""

exit 0