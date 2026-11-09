# iospro-r8q

> **UniXNU / HackiOS boot framework for Samsung Galaxy S20 FE 5G (`r8q` / SM8250)** — real pipeline edition.

[![Build XNU Kernel](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-kernel.yml)
[![Build r8q UEFI Firmware](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-firmware.yml/badge.svg)](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-firmware.yml)
[![Build r8q Payload](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-payload.yml/badge.svg)](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-payload.yml)
[![Assemble boot.img](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-bootimg.yml/badge.svg)](https://github.com/Camgobeg/iospro-r8q/actions/workflows/build-bootimg.yml)

---

## 🇹🇷 Ne bu proje?

Samsung Galaxy S20 FE 5G (`r8q`, SM-G780G, Snapdragon 865) üzerinde Apple'ın
XNU (Darwin) çekirdeğini başlatmak için **gerçek, kanıtlanmış UniXNU
pipeline'ı**. Bu depo artık sahte stub üreten değil; telefonda boot testinden
geçmiş bileşenlerin CI otomasyonudur.

### Mimari (gerçek boot akışı)

```
boot.img (Android boot image, header v1, 4096 sayfa)
├── kernel alanı : gzip(BootShim + SILICIUM_UEFI.fd 3 MiB) + live.dtb
│                  └── BootShim UEFI'yi 0x9FC00000'e kopyalar, ABL'nin FDT'sini korur
├── ramdisk      : payload.img (56 MiB FAT — kernel.macho + ADT + unixnu.toml)
│                  └── ABL initrd'yi RAM'e koyup FDT'ye initrd-start/end yazar
└── (dtb)        : telefonun kendi live device tree'si (cont_splash korunur)

UEFI (Mu-Silicium r8qPkg) → UniXNURamDiskDxe initrd'yü BlockIo yapar
→ Fat mounts → UniXNU menüsü → DarwinBoot → XNU kernel.macho
```

### Depo düzeni

| Yol | İçerik |
| --- | --- |
| `.github/workflows/build-kernel.yml` | macOS runner'da gerçek XNU derlemesi (UniXNU build driver, device repo `Camgobeg/UniXNU-r8q`) |
| `.github/workflows/build-firmware.yml` | Mu-Silicium `r8qPkg` UEFI firmware'i (uefi-sheng + device yaması) |
| `.github/workflows/build-payload.yml` | kernel.macho + ADT → 56 MiB FAT payload |
| `.github/workflows/build-bootimg.yml` | FD + payload + live.dtb → flash'lanabilir `boot.img` |
| `tools/backup-partitions.sh` | Root ADB ile stock boot/dtbo/vbmeta yedeği |
| `tools/flash-safe.sh` | Blocklist'li güvenli flash (sadece `boot`) |
| `tools/test-boot.sh` | `fastboot boot` ile RAM'de geçici test |
| `tools/make-odin-tar.py` | Odin `.tar.md5` paketleyici |

live.dtb (telefonun kendi FDT'si) `Camgobeg/UniXNU-r8q` deposunda:
`boot/live.dtb` — bootimg workflow'u oradan okur.

### Kullanım (CI)

1. **Build XNU Kernel** workflow'unu dispatch et → `kernel-r8q` artifact
2. **Build r8q UEFI Firmware** → `firmware-r8q-DEBUG`
3. **Build r8q Payload** (kernel run id + `UNIXNU_UNIQUE_CHIP_ID` secret gerekir)
4. **Assemble r8q boot.img** (firmware + payload run id) → `boot-r8q`
5. `tools/flash-safe.sh boot.img` (önce yedek!)

### Yerel derleme (WSL)

```sh
git clone -b r8q-ci https://github.com/Camgobeg/UniXNU UniXNU-ci
git clone https://github.com/Camgobeg/UniXNU-r8q
git clone https://github.com/UniXNU/uefi-sheng Mu-Silicium
git -C Mu-Silicium apply UniXNU-r8q/docs/patches/mu-silicium-r8q.patch

cd UniXNU-ci
./unixnu fetch -D ../UniXNU-r8q
./unixnu build kernel          # macOS gerekir (veya CI artifact'ı kullan)
./unixnu build payload -D ../UniXNU-r8q --kernel <kernel.macho> \
    --uefi ../Mu-Silicium --unique-chip-id <hex>
./unixnu build firmware -D ../UniXNU-r8q --uefi ../Mu-Silicium
./unixnu bootimg -D ../UniXNU-r8q --uefi ../Mu-Silicium \
    --fd <SILICIUM_UEFI.fd> --dtb <live.dtb> --ramdisk <payload.img> -o boot.img
```

---

## ⚠️ Önemli Güvenlik Kuralları (Brick Koruması)

1. **Asla Dokunulmayacak Kritik Bölümler:** `xbl`, `xbl_config`, `abl`, `tz`,
   `hyp`, `aop`, `modem`, `efs`, `sec_efs`, `persist` — bu bölümlere kesinlikle
   yazma/silme yapılmaz. **GPT tablosuna asla dokunulmaz.**
2. **Yalnızca Hedef Bölüm (`boot`):** Tüm derlemeler standart Android `boot.img`
   formatındadır; sadece `boot` bölümüne yazılır.
3. **Zorunlu Yedek:** `tools/backup-partitions.sh` ile yedek alınmadan flash yapılmaz.
4. **Onay:** `tools/flash-safe.sh` kullanıcıdan açık onay istemeden yazma yapmaz.

## Cihaz

- **Model:** SM-G780G (Galaxy S20 FE 5G, `r8q`)
- **SoC:** Snapdragon 865 (SM8250 / Kona), GICv3 `0x17A00000`/`0x17A60000`
- **Ekran:** 1080x2400 AMOLED (sw43404 panel sürücüsü)
- **Depolama:** UFS (host `0x01D84000`), boot bölümü 64 MiB
- **Bootloader:** Samsung ABL (header v1 / 4096 sayfa; imzasız `fastboot boot` reddedilir → flash `boot_a`)

## License & Disclaimers

- Apple, iOS, iPadOS, macOS and XNU are trademarks of Apple Inc.
- Independent open-source research/education project; no liability for device misuse.
