#!/bin/bash

# Ensure the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "Requesting root privileges..."
   exec sudo "$0" "$@"
fi

echo "--- Starting System Update Sequence ---"

# 1. Update package list
echo "Updating package lists..."
apt update -y

# 2. Upgrade current packages
echo "Upgrading installed packages..."
apt upgrade -y

# 3. Perform full-upgrade
echo "Performing full-upgrade..."
apt full-upgrade -y

# 4. Remove unused and clean up
echo "Cleaning up..."
apt autoremove -y && apt autoclean

echo "--- System maintenance completed successfully! ---"
