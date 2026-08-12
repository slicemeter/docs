#!/bin/sh
# Slicemeter CLI Companion Installer Script
# Usage: curl -fsSL https://slicemeter.com/install-cli.sh | sh

set -e

REPO="slicemeter/slicemeter"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Error: Unsupported architecture $ARCH"; exit 1 ;;
esac

case "$OS" in
    linux) OS="linux" ;;
    darwin) OS="darwin" ;;
    *) echo "Error: Unsupported operating system $OS"; exit 1 ;;
esac

echo "🚀 Installing Slicemeter CLI for ${OS}-${ARCH}..."

INSTALL_DIR="/usr/local/bin"
if [ ! -w "$INSTALL_DIR" ]; then
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi

# 1. If running inside the slicemeter repo, build directly from local source
if [ -f "cmd/slicemeter/main.go" ] && command -v go >/dev/null 2>&1; then
    echo "Building Slicemeter CLI from local source..."
    go build -o "$INSTALL_DIR/slicemeter" ./cmd/slicemeter
    echo "✅ Slicemeter CLI built and installed to $INSTALL_DIR/slicemeter"
    echo "Run 'slicemeter --help' to get started."
    exit 0
fi

# 2. Try fetching pre-compiled binary release asset from GitHub Releases
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/slicemeter-${OS}-${ARCH}.tar.gz"

echo "Downloading pre-compiled binary release from ${DOWNLOAD_URL}..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/slicemeter.tar.gz" 2>/dev/null; then
    tar -xzf "$TMP_DIR/slicemeter.tar.gz" -C "$TMP_DIR"
    chmod +x "$TMP_DIR/slicemeter"
    mv "$TMP_DIR/slicemeter" "$INSTALL_DIR/slicemeter"
    echo "✅ Slicemeter CLI installed to $INSTALL_DIR/slicemeter"
    echo "Run 'slicemeter --help' to get started."
    exit 0
fi

# 3. Fallback to Go Toolchain if available
if command -v go >/dev/null 2>&1; then
    echo "Installing via Go Toolchain (using GOPRIVATE fallback)..."
    GOPRIVATE="github.com/${REPO}" go install github.com/${REPO}/cmd/slicemeter@latest 2>/dev/null || \
    go install ./cmd/slicemeter 2>/dev/null || true
    if command -v slicemeter >/dev/null 2>&1; then
        echo "✅ Slicemeter CLI installed successfully!"
        echo "Run 'slicemeter --help' to get started."
        exit 0
    fi
fi

echo "❌ Installation failed. Please ensure Go is installed or download pre-compiled release binaries."
exit 1
