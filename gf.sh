#!/bin/bash

# Screen clear karein aur header dikhayein
clear
echo "========================================"
echo "    GF ADVANCED TARGET SCANNER          "
echo "========================================"

# User se file path mangna
read -p "Enter the full path of the URL file to scan: " target_file

# Check karna ki file exist karti hai ya nahi
if [ ! -f "$target_file" ]; then
    echo "[-] Error: File '$target_file' nahi mili!"
    exit 1
fi

# Results ke liye folder banana (Current directory mein)
output_dir="gf_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$output_dir"

echo "[+] Scanning started on: $target_file"
echo "[+] Results will be saved in: $output_dir"
echo "----------------------------------------"

# GF Loop shuru
for p in $(gf -list); do
    # Target file ko scan karna
    gf "$p" "$target_file" > "$output_dir/${p}.txt" 2>/dev/null

    # Agar results mile toh display karein, varna delete karein
    if [ -s "$output_dir/${p}.txt" ]; then
        count=$(wc -l < "$output_dir/${p}.txt")
        echo "[✓] $p: $count matches found"
    else
        rm -f "$output_dir/${p}.txt"
    fi
done

echo "----------------------------------------"
echo "[+] Scan Complete! Check the '$output_dir' folder."
