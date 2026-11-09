/*
 * XNULoader C Runtime for SM8250 (r8q)
 * Bridges Android/UEFI environment to Apple XNU boot_args
 */

#include <stdint.h>
#include <stddef.h>

#define BOOT_ARGS_VERSION 2

typedef struct {
    uintptr_t   v_baseAddr;
    uint32_t    v_display;
    uint32_t    v_rowBytes;
    uint32_t    v_width;
    uint32_t    v_height;
    uint32_t    v_depth;
} PE_Video;

struct boot_args {
    uint16_t    version;
    uint16_t    efiMode;
    uint32_t    flags;
    uint64_t    topOfKernelData;
    PE_Video    video;
    uint32_t    machineType;
    uint64_t    deviceTreeP;
    uint32_t    deviceTreeLength;
    char        CommandLine[1024];
    uint64_t    boot_args_phys;
};

/* Statically allocated boot_args passed to XNU */
static struct boot_args g_boot_args __attribute__((aligned(4096)));

/* Destination address of XNU kernel in RAM */
#define XNU_KERNEL_ENTRY 0x80200000ULL

static void string_copy(char *dst, const char *src, size_t max) {
    size_t i = 0;
    while (src[i] != '\0' && i < max - 1) {
        dst[i] = src[i];
        i++;
    }
    dst[i] = '\0';
}

void loader_main(void) {
    /* 1. Setup Boot Arguments */
    g_boot_args.version = BOOT_ARGS_VERSION;
    g_boot_args.efiMode = 2; /* 64-bit */
    g_boot_args.flags = 0;
    g_boot_args.machineType = 0x8250; /* SM8250 */
    g_boot_args.boot_args_phys = (uintptr_t)&g_boot_args;

    /* 2. Configure S20 FE 5G Framebuffer Console (SimpleFB) */
    g_boot_args.video.v_baseAddr = 0x9C000000ULL; /* Default Kona FB base */
    g_boot_args.video.v_width    = 1080;
    g_boot_args.video.v_height   = 2400;
    g_boot_args.video.v_depth    = 32;
    g_boot_args.video.v_rowBytes = 1080 * 4;
    g_boot_args.video.v_display  = 1;

    /* 3. Command Line */
    string_copy(g_boot_args.CommandLine, "console=simplefb -v debug=0x14e cs_enforcement=0 amfid=0", sizeof(g_boot_args.CommandLine));

    /* 4. Branch to Apple XNU kernel */
    typedef void (*xnu_entry_t)(struct boot_args *args);
    xnu_entry_t entry = (xnu_entry_t)XNU_KERNEL_ENTRY;

    entry(&g_boot_args);
}
