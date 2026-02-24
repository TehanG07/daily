#!/bin/bash

echo "====== PORTABLE TOOL INSTALLER ======"

BASE="$PWD/tool/mytools"

echo "[+] Creating folders at: $BASE"
mkdir -p "$BASE"
cd "$BASE" || exit

echo "[+] Installing dependencies"
sudo apt update
sudo apt install -y git python3 python3-pip

echo "[+] Cloning tools"
git clone https://github.com/TehanG07/juicy.git
git clone https://github.com/TehanG07/sql-detecor.git

echo "[+] Setting permissions"
chmod -R +x juicy || true
chmod -R +x sql-detecor || true

echo "[+] Installing python requirements if present"
for d in juicy sql-detecor; do
if [ -f "$d/requirements.txt" ]; then
pip3 install -r "$d/requirements.txt"
fi
done

echo ""
echo "====== INSTALL COMPLETED ======"
echo "Installed at: $BASE"
