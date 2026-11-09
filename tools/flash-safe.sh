#!/usr/bin/env bash
set -euo pipefail

# iospro-r8q Safe Flashing Utility with Strict Safeguards
# PROTECTS CRITICAL HARDWARE PARTITIONS FROM ACCIDENTAL OVERWRITES

IMAGE_FILE="${1:-}"
TARGET_PARTITION="${2:-boot}"

echo "=========================================================="
echo "      ⚠️  iospro-r8q SAFE FLASHING INTERFACE  ⚠️          "
echo " Target Device: Samsung Galaxy S20 FE 5G (r8q)            "
echo " Image File: ${IMAGE_FILE}                                "
echo " Target Partition: ${TARGET_PARTITION}                    "
echo "=========================================================="

if [ -z "${IMAGE_FILE}" ] || [ ! -f "${IMAGE_FILE}" ]; then
    echo "[-] Error: Please specify a valid image file to flash."
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

# Permitted flashing targets
ALLOWED_TARGETS=("boot" "boot_a" "boot_b")
IS_ALLOWED=0
for allowed in "${ALLOWED_TARGETS[@]}"; do
    if [ "${TARGET_PARTITION}" = "${allowed}" ]; then
        IS_ALLOWED=1
        break
    fi
done

if [ "${IS_ALLOWED}" -ne 1 ]; then
    echo "[-] Warning: '${TARGET_PARTITION}' is not a standard boot partition."
    echo "    Permitted safe targets: ${ALLOWED_TARGETS[*]}"
    exit 1
fi

echo ""
echo "FILE DETAILS:"
echo " - Path: ${IMAGE_FILE}"
echo " - Size: $(stat -c%s "${IMAGE_FILE}" 2>/dev/null || wc -c < "${IMAGE_FILE}") bytes"
echo " - SHA256: $(sha256sum "${IMAGE_FILE}" | cut -d' ' -f1)"
echo ""
echo "⚠️  MANDATORY USER CONFIRMATION REQUIRED:"
echo "   Are you ABSOLUTELY sure you want to flash '${IMAGE_FILE}'"
echo "   to the '${TARGET_PARTITION}' partition on device?"
echo ""
read -r -p "Type 'CONFIRM_FLASH' to proceed, or anything else to cancel: " USER_INPUT

if [ "${USER_INPUT}" != "CONFIRM_FLASH" ]; then
    echo "[*] Flashing cancelled by user. No partitions were modified."
    exit 0
fi

echo ""
echo "[*] Proceeding with flashing via fastboot..."
if fastboot devices | grep -q "fastboot"; then
    echo "[*] Flashing ${IMAGE_FILE} to ${TARGET_PARTITION}..."
    fastboot flash "${TARGET_PARTITION}" "${IMAGE_FILE}"
    echo "[✓] Flash completed successfully."
else
    echo "[*] Fastboot device not detected. Checking ADB root..."
    if adb shell "id -u" 2>/dev/null | grep -q "0"; then
        echo "[*] Uploading image to device /data/local/tmp..."
        adb push "${IMAGE_FILE}" /data/local/tmp/new_image.img
        echo "[*] Writing image to /dev/block/bootdevice/by-name/${TARGET_PARTITION}..."
        adb shell "dd if=/data/local/tmp/new_image.img of=/dev/block/bootdevice/by-name/${TARGET_PARTITION} bs=4096"
        adb shell "rm -f /data/local/tmp/new_image.img"
        echo "[✓] Flash completed via ADB root."
    else
        echo "[-] Error: Neither fastboot nor adb root device was detected!"
        exit 1
    fi
fi
