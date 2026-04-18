#!/bin/bash

# Ensure the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)." 
   exit 1
fi

echo "--- Starting System Update Sequence ---"

# 1. Update package list
echo "[1/5] Updating package lists..."
apt update -y

# 2. Upgrade current packages
echo "[2/5] Upgrading installed packages..."
apt upgrade -y

# 3. Perform full-upgrade (handles dependency changes)
echo "[3/5] Performing full-upgrade..."
apt full-upgrade -y

# 4. Remove unused dependencies
echo "[4/5] Removing orphaned dependencies..."
apt autoremove -y

# 5. Clean up local package cache
echo "[5/5] Cleaning up package cache..."
apt autoclean

echo "--- System maintenance completed successfully! ---"
