# iospro-r8q

> **UniXNU / HackiOS Porting & Bootloader Framework for Samsung Galaxy S20 FE 5G (`r8q` / SM8250)**

[![Build Darwin XNU Kernel](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-kernel.yml)
[![Build SM8250 UEFI](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-uefi.yml/badge.svg)](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-uefi.yml)
[![Build RootFS Ramdisk](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-rootfs.yml/badge.svg)](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-rootfs.yml)
[![Assemble Android boot.img](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-bootimg.yml/badge.svg)](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-bootimg.yml)

---

## 🇹🇷 Türkçe Açıklama

Bu proje, **Samsung Galaxy S20 FE 5G (`r8q`)** cihazında bulunan **Qualcomm Snapdragon 865 (SM8250 / Kona)** platformu üzerinde Apple'ın açık kaynaklı **XNU (Darwin) çekirdeğini** ve **UniXNU / HackiOS** tabanlı Mach-O kullanıcı ortamını başlatmak için geliştirilmiş özel bootloader, çekirdek yamaları ve GitHub Actions derleme altyapısıdır.

### ⚠️ Önemli Güvenlik Kuralları (Brick Koruması)
Cihazın brick olmasını (kalıcı olarak kullanılamaz hale gelmesini) önlemek için projede katı güvenlik önlemleri alınmıştır:
1. **Asla Dokunulmayacak Kritik Bölümler (Blocklist):**
   - `xbl`, `xbl_config`, `abl`, `tz` (TrustZone), `hyp`, `aop`, `modem`, `efs`, `sec_efs`, `persist`.
   - Bu bölümlere kesinlikle yazma/silme işlemi yapılmaz.
2. **Yalnızca Hedef Bölüm (`boot`):**
   - Yapılan tüm derlemeler standart Android `boot.img` formatında paketlenir.
   - Sadece `boot` (veya `boot_a` / `boot_b`) bölümüne yazılır.
3. **RAM Üzerinden Risksiz Test:**
   - Cihaza kalıcı flaş yapmadan önce `fastboot boot boot.img` komutu ile geçici olarak test edilir. Cihaz hafızasına tek bir bayt bile yazılmaz!
4. **Zorunlu Onay ve Yedekleme:**
   - `tools/backup-partitions.sh` ile stock `boot`, `recovery`, `dtbo`, `vbmeta` bölümlerinin tam yedeği alınmadan işlem yapılmaz.
   - `tools/flash-safe.sh` scripti kullanıcıdan açıkça onay (`CONFIRM_FLASH`) istemeden yazma yapmaz.

---

## 🇬🇧 English Description

This project provides the bootloader framework, hardware adaptation patches, and automated GitHub Actions CI/CD pipelines to port and boot Apple's open-source **XNU (Darwin) kernel** on the **Samsung Galaxy S20 FE 5G (`r8q`)** powered by **Qualcomm Snapdragon 865 (SM8250)**.

### Target Device Specifications
- **Device Model:** Samsung Galaxy S20 FE 5G (`SM-G781B` / `SM-G781U`)
- **Codename:** `r8q`
- **SoC:** Qualcomm Snapdragon 865 (`SM8250` / `Kona`)
- **CPU:** 8 Cores (1x Cortex-A77 Prime @ 2.84 GHz, 3x Cortex-A77 Gold @ 2.42 GHz, 4x Cortex-A55 Silver @ 1.80 GHz)
- **GPU:** Qualcomm Adreno 650
- **Display:** 1080x2400 Super AMOLED @ 120Hz
- **Bootloader:** Qualcomm ABL (Android Boot Loader)

---

## 📂 Repository Layout

```text
iospro-r8q/
├── .github/workflows/
│   ├── build-kernel.yml        # XNU Kernel cross-compilation pipeline
│   ├── build-uefi.yml          # EDK2 / XNULoader build pipeline
│   ├── build-rootfs.yml        # Darwin Mach-O initrd generator
│   └── build-bootimg.yml       # Android boot.img packaging pipeline
├── boot/
│   ├── android/
│   │   ├── bootimg.cfg         # Kernel offsets, page size (4096), cmdline
│   │   └── mkbootimg.py        # Android header v2 boot image builder
│   └── xnuloader/
│       ├── entry.S             # ARM64 EL2->EL1 vector and MMU setup
│       ├── main.c              # Video console & boot_args structure builder
│       └── Makefile            # Loader build rule
├── kernel/
│   ├── configs/                # Target machine definition
│   ├── patches/                # Hardware adaptation patches
│   │   ├── 0001-sm8250-gicv3-support.patch     # ARM GICv3 interrupt controller
│   │   ├── 0002-sm8250-generic-timer.patch    # ARMv8 generic architected timer
│   │   ├── 0003-sm8250-simplefb-console.patch  # Framebuffer console (1080x2400)
│   │   ├── 0004-sm8250-4k-pagesize.patch       # Force 4KB page size translation
│   │   ├── 0005-bypass-sep-amfid-checks.patch # Stub SEP and AMFID enforcement
│   │   └── 0006-sm8250-psci-smp.patch          # PSCI multi-core bringup
│   └── scripts/
│       └── build-kernel.sh     # Source fetcher and compiler
├── rootfs/
│   ├── overlay/                # Minimal Darwin filesystem overlay (/sbin/init, etc.)
│   └── scripts/
│       ├── make-ramdisk.sh     # Initial ramdisk generator
│       └── ipsw-extractor.py   # Apple IPSW component extractor
├── tools/
│   ├── backup-partitions.sh    # Dumps stock partitions via root ADB
│   ├── flash-safe.sh           # Safe flashing script with strict blocklists
│   └── test-boot.sh            # Safe RAM boot via 'fastboot boot'
└── docs/
    ├── ARCHITECTURE.md         # Hardware & low-level porting documentation
    ├── PARTITIONS_AND_SAFETY.md# Partition safety ratings and blocklists
    └── BOOT_FLOW.md            # Boot sequence diagrams and boot_args spec
```

---

## 🚀 Quick Start Guide

### 1. Partition Backup (STOCK YEDEK ALMA)
Telefon ADB üzerinden root yetkisiyle bağlıyken stock bölümlerin yedeğini alın:
```bash
chmod +x tools/*.sh
./tools/backup-partitions.sh
```
Bu komut `boot`, `recovery`, `dtbo` ve `vbmeta` bölümlerini çekip `backups/` klasörüne SHA256 özetleriyle kaydeder.

### 2. Risksiz Geçici Test (RAM Boot)
Cihazı fastboot moduna alın (`adb reboot bootloader`) ve kalıcı flaş yapmadan RAM'de test edin:
```bash
./tools/test-boot.sh out/boot.img
```
Bu yöntem cihaz hafızasına hiçbir şey yazmaz; yeniden başlattığınızda telefon normal Android'e döner.

### 3. Kalıcı Flaş (Yalnızca Boot Bölümüne)
```bash
./tools/flash-safe.sh out/boot.img boot
```
Script kritik bölümlere (`xbl`, `abl`, `tz`, `efs`, vb.) yazmayı otomatik olarak engeller ve işlem öncesinde onay ister.

---

## 🛠️ GitHub Actions CI/CD
Tüm derleme işlemleri GitHub Actions bulut sunucularında otomatik olarak çalışır:
- Çekirdek yamalandığında: `build-kernel.yml` tetiklenir.
- Loader güncellendiğinde: `build-uefi.yml` tetiklenir.
- Ramdisk değiştiğinde: `build-rootfs.yml` tetiklenir.
- Tüm bileşenler hazır olduğunda: `build-bootimg.yml` çalışır ve indirilebilir `boot.img` üretir.

---

## 📜 License & Disclaimers
- Apple, iOS, iPadOS, macOS, and XNU are trademarks of Apple Inc.
- This project is an independent open-source research and educational porting endeavor.
- The authors and contributors assume no liability for device misuse. Follow safety guidelines at all times.
