#!/bin/bash

# Ensure the script runs as root/with sudo
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root"
  exit 1
fi

echo "===== STARTING SYSTEM UPDATE ====="

# Update package lists
echo "Updating package lists..."
apt update -y

# Perform full upgrade
echo "Performing full upgrade..."
apt full-upgrade -y

# Clean up unnecessary packages
echo "Removing unused packages..."
apt autoremove -y
apt autoclean

echo "=================================="
echo "[✓] System update and cleanup complete!"
