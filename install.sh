#!/bin/bash
# VOD Copyright Removal - Universal Installer

set -e

echo "==================================="
echo "VOD Copyright Removal Pipeline Setup"
echo "==================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: Please run as root (use sudo ./install.sh)"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run the main setup
bash "$SCRIPT_DIR/scripts/setup-system.sh"

echo ""
echo "Installation complete!"
echo "Access the web interface at: http://$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo ""
