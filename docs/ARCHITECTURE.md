# iospro-r8q Architecture & Porting Specification

## 1. Overview
The **iospro-r8q** project implements a bootloader chain, patched Apple XNU (Darwin) kernel, and hybrid userspace runtime targeting the **Samsung Galaxy S20 FE 5G (`r8q` / SM-G781B / SM-G781U)** powered by the **Qualcomm Snapdragon 865 (SM8250 / Kona)** platform.

```
+-------------------------------------------------------------------+
|                     Samsung Galaxy S20 FE 5G                      |
|                  SoC: Qualcomm Snapdragon 865                     |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|               Primary Boot Chain (Samsung Knox / Qualcomm)        |
|  PBL -> XBL (eXtensible Boot Loader) -> AOP -> QSEE (TZ) -> ABL   |
+-------------------------------------------------------------------+
                                  |
                                  v  Loads Android boot.img
+-------------------------------------------------------------------+
|                    Stage 1: UEFI / XNULoader                      |
|  - Initializes ARM64 EL2/EL1                                      |
|  - Framebuffer Setup (SimpleFB GOP: 1080x2400 @ 32bpp)            |
|  - Populates XNU `boot_args` structure (cmdline, video, memmap)   |
+-------------------------------------------------------------------+
                                  |
                                  v  Jumps to Mach-O kernel entry
+-------------------------------------------------------------------+
|              Stage 2: Patched Apple XNU (Darwin) Kernel           |
|  - GICv3 Interrupt Controller (replaces Apple AIC)                |
|  - ARMv8 Architected Generic Timers (replaces Apple Timer)        |
|  - 4KB Translation Granule (TGran4 MMU)                           |
|  - PSCI SMP Core Bringup (CPU0-CPU7)                              |
|  - Stubbed SEP (Secure Enclave) & Disabled AMFID Code Integrity   |
+-------------------------------------------------------------------+
                                  |
                                  v  Mounts rootfs / Mach-O ramdisk
+-------------------------------------------------------------------+
|                     Stage 3: Darwin / iOS Userspace               |
|  - mach_init / launchd                                            |
|  - dyld (ARM64 Mach-O dynamic linker)                             |
|  - Serial / Framebuffer Terminal Console                          |
+-------------------------------------------------------------------+
```

---

## 2. Hardware Architecture vs Apple Silicon

| Subsystem | Apple Silicon (e.g. A13/A14) | Qualcomm Snapdragon 865 (SM8250) | Porting Strategy |
| :--- | :--- | :--- | :--- |
| **CPU Architecture** | ARMv8.4-A / ARMv8.5-A (Firestorm/Icestorm) | ARMv8.2-A (1x Cortex-A77 @ 2.84GHz, 3x A77, 4x A55) | Compatible ARM64 ISA; compile with `-march=armv8.2-a`. |
| **Interrupt Controller** | Apple AIC (Proprietary MMIO) | ARM GICv3 (Distributor + Redistributors) | Replaced AIC driver in XNU PE (`Platform Expert`) with GICv3 MMIO driver. |
| **Timer** | Apple ARM Proprietary Timer | ARMv8 Generic Architected Timer (`CNTPCT_EL0`) | Mapped `CNTP_TVAL_EL0` & `CNTP_CTL_EL0` to Darwin mach timer subsystem. |
| **MMU Page Granule** | 16KB default (`TGran16`) | 4KB (`TGran4`) / 64KB (`TGran64`) | Cortex-A77 lacks native 16KB hardware granule. Kernel patched to enforce 4KB pages (`PAGE_SIZE=4096`). |
| **SMP Boot (Secondary Cores)** | Apple proprietary mailbox / power control | ARM PSCI v1.0 (via SMC/HVC calls) | Implemented `psci_cpu_on` routine in `arm_init.c`. |
| **Graphics Output** | Apple AGX GPU + Metal Driver | Qualcomm Adreno 650 GPU | Early console uses UEFI GOP / SimpleFB linear framebuffer (1080x2400x4). |
| **Security Coprocessor** | Apple SEP (Secure Enclave Processor) | Qualcomm QSEE / TrustZone | SEP IPC calls stubbed in kernel; cryptographic tickets bypassed. |
| **Code Signing** | Apple AMFID + FairPlay | Android dm-verity / AVB | AMFID integrity checks bypassed; `cs_enforcement=0` cmdline enforced. |

---

## 3. Bootloader Integration
Qualcomm ABL (Android Boot Loader) boots images packaged in the standard **Android `boot.img`** format. To run XNU:
1. The **XNULoader** ELF binary is placed as the `kernel` payload in `boot.img`.
2. The Mach-O XNU kernel (`mach_kernel.arm64`) and Device Tree (`r8q.dtb`) are packaged into the ramdisk/appended payloads.
3. ABL jumps to XNULoader at `0x80000000`.
4. XNULoader parses ATAGS/FDT, detects the framebuffer at `0x9C000000` (or dynamically allocated via UEFI GOP), initializes `boot_args`, relocates `mach_kernel`, and branches to `kernel_entry`.

---

## 4. Safety Guarantee
No operations ever write to baseband, modem, TrustZone, or bootloader partitions. All testing is conducted strictly via:
1. `fastboot boot boot.img` (RAM-only execution, zero flash impact).
2. ADB root partition backups prior to any deployment.
