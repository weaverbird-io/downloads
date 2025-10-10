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

# Check if apt is available
has_apt() {
    command -v apt-get >/dev/null 2>&1
}

# Add WeaverBird APT repository
add_apt_repository() {
    echo "${YELLOW}Adding WeaverBird APT repository...${NC}"

    # Add repository to sources list
    APT_REPO_URL="https://weaverbird-io.github.io/downloads/apt"
    SOURCES_FILE="/etc/apt/sources.list.d/weaverbird.list"

    echo "deb [trusted=yes] ${APT_REPO_URL} stable main" | sudo tee "$SOURCES_FILE" > /dev/null

    if [ -f "$SOURCES_FILE" ]; then
        echo "${GREEN}✓ Repository added${NC}"
        return 0
    else
        echo "${RED}Failed to add repository${NC}"
        return 1
    fi
}

# Install via APT (from our repository)
install_via_apt() {
    echo "${BLUE}Installing via APT...${NC}"

    if ! has_apt; then
        echo "${RED}APT is not available on this system${NC}"
        return 1
    fi

    # Add WeaverBird repository
    if ! add_apt_repository; then
        echo "${YELLOW}Failed to add repository, trying direct DEB download...${NC}"
        install_deb_direct
        return $?
    fi

    # Update package list
    echo "${YELLOW}Updating package list...${NC}"
    sudo apt-get update -qq

    # Install weaverbird
    if sudo apt-get install -y weaverbird; then
        echo "${GREEN}✓ Installed via APT${NC}"
        echo "${GREEN}✓ You will receive automatic updates via apt upgrade${NC}"
        return 0
    else
        echo "${YELLOW}APT installation failed, trying direct DEB download...${NC}"
        install_deb_direct
        return $?
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

            # Add APT repository for future updates
            if has_apt; then
                echo "${YELLOW}Adding APT repository for automatic updates...${NC}"
                add_apt_repository || true  # Don't fail if this doesn't work
            fi

            rm -rf "$TMP_DIR"
            return 0
        fi
    fi

    rm -rf "$TMP_DIR"
    echo "${YELLOW}DEB installation failed, trying binary install...${NC}"
    return 1
}

# Determine best installation method
choose_install_method() {
    case "$INSTALL_METHOD" in
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
            # Try APT installation first (recommended - gets automatic updates)
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
    echo "  • APT (recommended) - for Debian/Ubuntu with automatic updates"
    echo "  • DEB - direct .deb package installation"
    echo "  • Binary - for other Linux distributions"
    echo ""
    echo "To force a specific method, set INSTALL_METHOD:"
    echo "  INSTALL_METHOD=apt curl -fsSL ... | sh"
    echo "  INSTALL_METHOD=deb curl -fsSL ... | sh"
    echo "  INSTALL_METHOD=binary curl -fsSL ... | sh"
    echo ""

    choose_install_method
    verify_installation

    echo ""
    echo "${GREEN}Happy weaving! 🕊️${NC}"
    echo ""
}

main
