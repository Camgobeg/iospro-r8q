#!/usr/bin/env bash
set -euo pipefail

# iospro-r8q Safe Flashing Utility with Strict Safeguards
# Supports Samsung Download Mode (.tar.md5) and Root ADB block flashing

IMAGE_FILE="${1:-out/boot.img}"
TARGET_PARTITION="${2:-boot}"

echo "=========================================================="
echo "      ⚠️  iospro-r8q SAFE FLASHING INTERFACE  ⚠️          "
echo " Target Device: Samsung Galaxy S20 FE (r8q / SM-G780G)    "
echo " Image File: ${IMAGE_FILE}                                "
echo " Target Partition: ${TARGET_PARTITION}                    "
echo "=========================================================="

if [ -z "${IMAGE_FILE}" ] || [ ! -f "${IMAGE_FILE}" ]; then
    echo "[-] Error: Please specify a valid boot image file."
    echo "    Usage: $0 <path_to_boot.img> [target_partition]"
    exit 1
fi

# CRITICAL PARTITIONS BLOCKLIST
CRITICAL_BLACKLIST=("xbl" "xbl_a" "xbl_b" "xbl_config" "xbl_config_a" "xbl_config_b" \
                    "abl" "abl_a" "abl_b" "tz" "tz_a" "tz_b" "hyp" "hyp_a" "hyp_b" \
                    "aop" "aop_a" "aop_b" "modem" "efs" "sec_efs" "persist" "devinfo")

for blacklisted in "${CRITICAL_BLACKLIST[@]}"; do
    if [ "${TARGET_PARTITION}" = "${blacklisted}" ]; then
        echo ""
        echo "🛑 [ABORT] CRITICAL SAFETY VIOLATION!"
        echo "   Target partition '${TARGET_PARTITION}' is a hardware/bootloader critical partition."
        echo "   Modifying this partition WILL hard-brick the device."
        echo "   Flashing to this partition is strictly forbidden by policy."
        exit 137
    fi
done

# Permitted targets
if [ "${TARGET_PARTITION}" != "boot" ]; then
    echo "[-] Error: On Samsung r8q, safe flashing is strictly limited to the 'boot' partition."
    exit 1
fi

echo ""
echo "FILE DETAILS:"
echo " - Path: ${IMAGE_FILE}"
echo " - Size: $(stat -c%s "${IMAGE_FILE}" 2>/dev/null || wc -c < "${IMAGE_FILE}") bytes"
echo " - SHA256: $(sha256sum "${IMAGE_FILE}" | cut -d' ' -f1)"
echo ""
echo "FLASHING OPTIONS FOR SAMSUNG (NO FASTBOOT):"
echo " [1] Package into Samsung Odin .tar.md5 (for Download Mode)"
echo " [2] Flash directly to /dev/block/bootdevice/by-name/boot via Root ADB"
echo ""
read -r -p "Select option (1 or 2): " FLASH_OPT

if [ "${FLASH_OPT}" = "1" ]; then
    OUT_ODIN="out/boot_odin_AP.tar.md5"
    python3 tools/make-odin-tar.py "${IMAGE_FILE}" -o "${OUT_ODIN}"
    echo ""
    echo "=========================================================="
    echo "[✓] Odin package created: ${OUT_ODIN}"
    echo "HOW TO FLASH IN DOWNLOAD MODE:"
    echo " 1. Turn off phone."
    echo " 2. Hold Vol Down + Vol Up and plug in USB to enter Download Mode."
    echo " 3. Press Vol Up to confirm Download Mode."
    echo " 4. Open Odin on PC, select '${OUT_ODIN}' in the 'AP' slot."
    echo " 5. Click Start!"
    echo "=========================================================="
    exit 0
fi

if [ "${FLASH_OPT}" = "2" ]; then
    echo ""
    echo "⚠️  MANDATORY USER CONFIRMATION REQUIRED:"
    echo "   Are you ABSOLUTELY sure you want to write '${IMAGE_FILE}'"
    echo "   directly to '/dev/block/bootdevice/by-name/boot' via ADB root?"
    echo ""
    read -r -p "Type 'CONFIRM_FLASH' to proceed, or anything else to cancel: " USER_INPUT

    if [ "${USER_INPUT}" != "CONFIRM_FLASH" ]; then
        echo "[*] Flashing cancelled by user. No partitions were modified."
        exit 0
    fi

    echo "[*] Checking ADB root connectivity..."
    ADB_ID=$(adb shell "id -u" 2>/dev/null | tr -d '\r')
    if [ "${ADB_ID}" != "0" ]; then
        echo "[-] Error: ADB root not active (uid=${ADB_ID}). Cannot flash."
        exit 1
    fi

    echo "[*] Uploading image to device /data/local/tmp..."
    adb push "${IMAGE_FILE}" /data/local/tmp/new_boot.img
    echo "[*] Writing to /dev/block/bootdevice/by-name/boot..."
    adb shell "dd if=/data/local/tmp/new_boot.img of=/dev/block/bootdevice/by-name/boot bs=4096"
    adb shell "rm -f /data/local/tmp/new_boot.img"
    echo "[✓] Flash completed successfully via ADB root."
fi
