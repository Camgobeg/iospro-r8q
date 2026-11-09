#!/usr/bin/env bash
set -euo pipefail

# iospro-r8q Non-Persistent RAM Boot Script
# Boots an image temporarily without touching internal flash memory.

IMAGE_FILE="${1:-out/boot.img}"

echo "=========================================================="
echo " [iospro-r8q] Non-Persistent RAM Boot Test               "
echo " Image: ${IMAGE_FILE}                                    "
echo "=========================================================="

if [ ! -f "${IMAGE_FILE}" ]; then
    echo "[-] Error: Boot image file not found: ${IMAGE_FILE}"
    exit 1
fi

echo "[*] Checking for Fastboot device..."
if ! fastboot devices | grep -q "fastboot"; then
    echo "[-] No fastboot device detected!"
    echo "    To enter fastboot on Samsung Galaxy S20 FE 5G:"
    echo "    1. Connect phone via USB"
    echo "    2. Run: adb reboot bootloader (or adb reboot fastboot)"
    exit 1
fi

echo "[*] Booting image in RAM via 'fastboot boot'..."
echo "    NOTE: Internal flash storage will NOT be modified."
fastboot boot "${IMAGE_FILE}"

echo "[✓] Boot command sent to device. Check device screen for console output."
