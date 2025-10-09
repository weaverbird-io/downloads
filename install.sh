#!/bin/sh
# WeaverBird CLI Installation Script
# Usage: curl -fsSL https://weaverbird-io.github.io/downloads/install.sh | sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation method preference
INSTALL_METHOD="${INSTALL_METHOD:-auto}"  # auto, snap, apt, binary

# Detect OS and architecture
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux*)
            OS_TYPE="linux"
            ;;
        *)
            echo "${RED}Unsupported operating system: $OS${NC}"
            echo "${YELLOW}Currently only Linux is supported${NC}"
            exit 1
            ;;
    esac

    case "$ARCH" in
        x86_64|amd64)
            ARCH_TYPE="amd64"
            ;;
        aarch64|arm64)
            ARCH_TYPE="arm64"
            ;;
        armv7l)
            ARCH_TYPE="armv7"
            ;;
        *)
            echo "${RED}Unsupported architecture: $ARCH${NC}"
            exit 1
            ;;
    esac

    PLATFORM="${OS_TYPE}-${ARCH_TYPE}"
    echo "${GREEN}Detected platform: $PLATFORM${NC}"
}

# Get latest release version from GitHub
get_latest_version() {
    echo "${YELLOW}Fetching latest version...${NC}"
    LATEST_VERSION=$(curl -sL https://api.github.com/repos/weaverbird-io/downloads/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$LATEST_VERSION" ]; then
        echo "${RED}Failed to fetch latest version${NC}"
        exit 1
    fi

    echo "${GREEN}Latest version: $LATEST_VERSION${NC}"
}

# Download and install binary
install_binary() {
    BINARY_NAME="weaverbird-cli-${PLATFORM}"
    DOWNLOAD_URL="https://github.com/weaverbird-io/downloads/releases/download/${LATEST_VERSION}/${BINARY_NAME}.tar.gz"

    echo "${YELLOW}Downloading from: $DOWNLOAD_URL${NC}"

    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    # Download the binary
    if ! curl -sL "$DOWNLOAD_URL" -o weaverbird-cli.tar.gz; then
        echo "${RED}Failed to download binary${NC}"
        echo "${YELLOW}URL: $DOWNLOAD_URL${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Extract
    echo "${YELLOW}Extracting...${NC}"
    tar -xzf weaverbird-cli.tar.gz

    # Install to /usr/local/bin (requires sudo)
    INSTALL_DIR="/usr/local/bin"

    if [ -w "$INSTALL_DIR" ]; then
        mv weaverbird "$INSTALL_DIR/weaverbird"
    else
        echo "${YELLOW}Installing to $INSTALL_DIR (requires sudo)${NC}"
        sudo mv weaverbird "$INSTALL_DIR/weaverbird"
    fi

    chmod +x "$INSTALL_DIR/weaverbird"

    # Cleanup
    cd -
    rm -rf "$TMP_DIR"

    echo "${GREEN}✓ WeaverBird CLI installed successfully!${NC}"
}

# Verify installation
verify_installation() {
    if command -v weaverbird >/dev/null 2>&1; then
        VERSION=$(weaverbird --version 2>/dev/null || echo "unknown")
        echo "${GREEN}✓ Installation verified${NC}"
        echo "${GREEN}Version: $VERSION${NC}"
        echo ""
        echo "Run 'weaverbird --help' to get started"
    else
        echo "${RED}Installation verification failed${NC}"
        exit 1
    fi
}

# Check if snap is available
has_snap() {
    command -v snap >/dev/null 2>&1
}

# Check if apt is available
has_apt() {
    command -v apt-get >/dev/null 2>&1
}

# Install via snap
install_via_snap() {
    echo "${BLUE}Installing via Snap...${NC}"

    if ! has_snap; then
        echo "${RED}Snap is not installed on this system${NC}"
        return 1
    fi

    if sudo snap install weaverbird 2>/dev/null; then
        echo "${GREEN}✓ Installed via Snap${NC}"
        return 0
    else
        echo "${YELLOW}Snap installation failed, trying alternative method...${NC}"
        return 1
    fi
}

# Install via APT (from PPA)
install_via_apt() {
    echo "${BLUE}Installing via APT...${NC}"

    if ! has_apt; then
        echo "${RED}APT is not available on this system${NC}"
        return 1
    fi

    echo "${YELLOW}Adding WeaverBird PPA...${NC}"

    # Add PPA
    if ! sudo add-apt-repository -y ppa:weaverbird/stable 2>/dev/null; then
        echo "${YELLOW}PPA not available yet, trying direct DEB download...${NC}"
        install_deb_direct
        return $?
    fi

    # Update and install
    sudo apt-get update -qq
    if sudo apt-get install -y weaverbird; then
        echo "${GREEN}✓ Installed via APT${NC}"
        return 0
    else
        echo "${YELLOW}APT installation failed, trying alternative method...${NC}"
        return 1
    fi
}

# Install DEB directly from GitHub
install_deb_direct() {
    echo "${BLUE}Installing DEB package from GitHub...${NC}"

    detect_platform
    get_latest_version

    # Strip cli-v prefix from version for DEB filename
    VERSION_NUM="${LATEST_VERSION#cli-v}"
    DEB_FILE="weaverbird_${VERSION_NUM}_${ARCH_TYPE}.deb"
    DOWNLOAD_URL="https://github.com/weaverbird-io/downloads/releases/download/${LATEST_VERSION}/${DEB_FILE}"

    echo "${YELLOW}Downloading: $DOWNLOAD_URL${NC}"

    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    if curl -sL "$DOWNLOAD_URL" -o "$DEB_FILE"; then
        if sudo dpkg -i "$DEB_FILE"; then
            sudo apt-get install -f -y  # Fix dependencies if needed
            echo "${GREEN}✓ Installed DEB package${NC}"
            cd -
            rm -rf "$TMP_DIR"
            return 0
        fi
    fi

    cd -
    rm -rf "$TMP_DIR"
    echo "${YELLOW}DEB installation failed, trying binary install...${NC}"
    return 1
}

# Determine best installation method
choose_install_method() {
    case "$INSTALL_METHOD" in
        snap)
            install_via_snap || exit 1
            ;;
        apt)
            install_via_apt || exit 1
            ;;
        deb)
            install_deb_direct || exit 1
            ;;
        binary)
            install_binary
            ;;
        auto)
            # Try snap first (works on all distros)
            if has_snap && install_via_snap; then
                return 0
            fi

            # Try APT on Debian/Ubuntu
            if has_apt && install_via_apt; then
                return 0
            fi

            # Fallback to direct binary installation
            echo "${YELLOW}Installing binary directly...${NC}"
            detect_platform
            get_latest_version
            install_binary
            ;;
        *)
            echo "${RED}Unknown installation method: $INSTALL_METHOD${NC}"
            exit 1
            ;;
    esac
}

# Main installation flow
main() {
    echo ""
    echo "${GREEN}🕊️  WeaverBird CLI Installer${NC}"
    echo ""
    echo "Installation methods available:"
    echo "  • Snap (recommended) - works on all Linux distros"
    echo "  • APT - for Debian/Ubuntu via PPA"
    echo "  • Binary - direct installation"
    echo ""
    echo "To force a specific method, set INSTALL_METHOD:"
    echo "  INSTALL_METHOD=snap curl -fsSL ... | sh"
    echo ""

    choose_install_method
    verify_installation

    echo ""
    echo "${GREEN}Happy weaving! 🕊️${NC}"
    echo ""
}

main
