#!/bin/bash

set -e  # error aate hi script stop

echo "===== APT UPDATE ====="
if sudo apt update; then
    echo "[✓] apt update successful"
else
    echo "[✗] apt update failed"
    exit 1
fi

echo "===== APT UPGRADE ====="
if sudo apt upgrade -y; then
    echo "[✓] apt upgrade successful"
else
    echo "[✗] apt upgrade failed"
    exit 1
fi

echo "===== APT FULL-UPGRADE ====="
if sudo apt full-upgrade -y; then
    echo "[✓] apt full-upgrade successful"
else
    echo "[✗] apt full-upgrade failed"
    exit 1
fi

echo "===== ALL DONE SUCCESSFULLY ====="
