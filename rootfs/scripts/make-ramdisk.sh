#!/usr/bin/env bash
set -euo pipefail

# Make Darwin Mach-O initial ramdisk (initrd) for iospro-r8q
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/rootfs"
OVERLAY_DIR="${ROOTFS_DIR}/overlay"
BUILD_DIR="${PROJECT_ROOT}/build/rootfs"
OUT_DIR="${PROJECT_ROOT}/out"

echo "=========================================================="
echo " [iospro-r8q] Building Darwin Mach-O Ramdisk (initrd)     "
echo "=========================================================="

mkdir -p "${BUILD_DIR}/root" "${OUT_DIR}"

# Populate essential directories
mkdir -p "${BUILD_DIR}/root"/{bin,sbin,etc,dev,tmp,var,usr/bin,usr/lib,System/Library}

# Copy overlay files
if [ -d "${OVERLAY_DIR}" ]; then
    cp -r "${OVERLAY_DIR}"/* "${BUILD_DIR}/root/"
fi

chmod +x "${BUILD_DIR}/root/sbin/init" 2>/dev/null || true
chmod +x "${BUILD_DIR}/root/etc/rc.local" 2>/dev/null || true

# Package into cpio.gz ramdisk
cd "${BUILD_DIR}/root"
find . | cpio -o -H newc | gzip -9 > "${OUT_DIR}/ramdisk.cpio.gz"

echo "[✓] Ramdisk built successfully: ${OUT_DIR}/ramdisk.cpio.gz"
