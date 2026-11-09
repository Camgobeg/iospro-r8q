# Samsung Galaxy S20 FE 5G (`r8q` / SM8250) Partition Layout & Safety Protocol

## ⚠️ STRICT SAFETY PROTOCOL
**Under NO circumstances will this project or its scripts write to, erase, or modify critical device partitions.**
Modifying bootloader or security partitions on Samsung Qualcomm devices without EDL firehose access can result in a permanent hard-brick.

---

## 1. Partition Map & Criticality Rating

| Partition Name | Block Device Path | Criticality | Modification Policy | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **`xbl_a` / `xbl_b`** | `/dev/block/bootdevice/by-name/xbl_*` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | eXtensible Boot Loader (Primary boot code) |
| **`xbl_config_*`** | `/dev/block/bootdevice/by-name/xbl_config_*`| 🔴 **CRITICAL** | ❌ **FORBIDDEN** | XBL hardware configuration table |
| **`abl_a` / `abl_b`** | `/dev/block/bootdevice/by-name/abl_*` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | Android Boot Loader (Fastboot & boot.img loader) |
| **`tz_a` / `tz_b`** | `/dev/block/bootdevice/by-name/tz_*` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | Qualcomm QSEE TrustZone / ARM TrustZone firmware |
| **`hyp_a` / `hyp_b`** | `/dev/block/bootdevice/by-name/hyp_*` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | Hypervisor firmware (EL2) |
| **`aop_a` / `aop_b`** | `/dev/block/bootdevice/by-name/aop_*` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | Always-On Processor power controller |
| **`modem`** | `/dev/block/bootdevice/by-name/modem` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | Qualcomm Baseband / Cellular modem firmware |
| **`efs` / `sec_efs`** | `/dev/block/bootdevice/by-name/efs` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | IMEI, Radio calibration, device cryptographic tokens |
| **`persist`** | `/dev/block/bootdevice/by-name/persist` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | Sensor calibration, fingerprint, factory persistent data |
| **`devinfo`** | `/dev/block/bootdevice/by-name/devinfo` | 🔴 **CRITICAL** | ❌ **FORBIDDEN** | Bootloader lock status flags |
| **`vbmeta_*`** | `/dev/block/bootdevice/by-name/vbmeta_*` | 🟡 **HIGH** | ⚠️ **ASK USER** | Android Verified Boot metadata |
| **`dtbo_*`** | `/dev/block/bootdevice/by-name/dtbo_*` | 🟡 **HIGH** | ⚠️ **ASK USER** | Device Tree Blob Overlay |
| **`recovery`** | `/dev/block/bootdevice/by-name/recovery` | 🟢 **MODERATE** | ⚠️ **ASK USER** | TWRP / Recovery environment (Rollback rescue) |
| **`boot_a` / `boot_b`**| `/dev/block/bootdevice/by-name/boot_*` | 🟢 **TARGET** | ⚠️ **CONFIRMATION REQUIRED** | Android Kernel + Ramdisk boot image |

---

## 2. Safety Enforcement Rules in Tooling

All scripts in the `tools/` directory enforce the following rules:

1. **Pre-Flight Backup Verification**:
   Before performing any operation, `tools/backup-partitions.sh` must be executed to dump existing `boot`, `recovery`, `dtbo`, and `vbmeta` partitions to disk and verify their SHA256 checksums.

2. **Prohibited Targets Check**:
   Any command attempting to write to `xbl`, `abl`, `tz`, `hyp`, `modem`, `efs`, or `persist` is intercepted and immediately aborted by `tools/flash-safe.sh`.

3. **Mandatory Interactive User Confirmation**:
   Even for allowed target partitions (`boot_a`, `boot_b`), the script will:
   - Display target partition name, size, and source file checksum.
   - Explicitly pause and ask the operator to type `CONFIRM_FLASH`.
   - Never flash automatically without manual consent.

4. **Fastboot RAM Boot Preference**:
   Flashing to internal UFS storage should only be done after successful verification via:
   ```bash
   fastboot boot boot.img
   ```
   This loads the kernel directly into memory without writing a single byte to internal storage.
