#!/usr/bin/env bash
set -euo pipefail

# iospro-r8q Partition Backup Script (Samsung Galaxy S20 FE 5G)
# Dumps stock boot, recovery, dtbo, and vbmeta partitions via root ADB.

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "${BACKUP_DIR}"

echo "=========================================================="
echo " [iospro-r8q] Device Partition Backup Utility             "
echo " Target: Samsung Galaxy S20 FE 5G (r8q - SM8250)          "
echo " Backup Destination: ${BACKUP_DIR}                       "
echo "=========================================================="

echo "[*] Verifying ADB root access..."
ADB_ROOT=$(adb shell "id -u" 2>/dev/null || echo "failed")
if [ "${ADB_ROOT}" != "0" ]; then
    echo "[-] ADB is not running with root privileges! Trying 'adb root'..."
    adb root || true
    sleep 2
    ADB_ROOT=$(adb shell "id -u" 2>/dev/null || echo "failed")
    if [ "${ADB_ROOT}" != "0" ]; then
        echo "[-] Error: Failed to acquire ADB root. Please authorize USB debugging on phone."
        exit 1
    fi
fi

echo "[✓] ADB root confirmed (uid=0)."

# Find active slot or partition paths
echo "[*] Detecting partition scheme..."
PART_DIR="/dev/block/bootdevice/by-name"

PARTITIONS=("boot" "boot_a" "boot_b" "recovery" "dtbo" "dtbo_a" "dtbo_b" "vbmeta" "vbmeta_a" "vbmeta_b")

for part in "${PARTITIONS[@]}"; do
    EXISTS=$(adb shell "[ -e ${PART_DIR}/${part} ] && echo 1 || echo 0" | tr -d '\r')
    if [ "${EXISTS}" = "1" ]; then
        echo "[*] Dumping partition: ${part}..."
        adb shell "dd if=${PART_DIR}/${part} of=/data/local/tmp/${part}.img bs=4096"
        adb pull "/data/local/tmp/${part}.img" "${BACKUP_DIR}/${part}.img"
        adb shell "rm -f /data/local/tmp/${part}.img"
        sha256sum "${BACKUP_DIR}/${part}.img" >> "${BACKUP_DIR}/sha256sums.txt"
    fi
done

echo "=========================================================="
echo "[✓] Backup completed successfully in: ${BACKUP_DIR}"
echo "    Checksums recorded in sha256sums.txt"
echo "=========================================================="
