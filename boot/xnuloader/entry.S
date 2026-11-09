/*
 * XNULoader ARM64 Entry Vector for Qualcomm SM8250 (r8q)
 * Receives execution from Android Boot Loader (ABL) or UEFI at 0x80000000
 */

.section .text.entry, "ax"
.global _start
.type _start, %function

_start:
    /* Mask all DAIF interrupts (Debug, SError, IRQ, FIQ) */
    msr daifset, #0xf

    /* Ensure we are executing in EL1 or drop from EL2 */
    mrs x0, CurrentEL
    lsr x0, x0, #2
    cmp x0, #2
    b.eq drop_from_el2
    b el1_entry

drop_from_el2:
    /* Configure HCR_EL2 for EL1 execution (RW=1 for AArch64) */
    mov x0, #(1 << 31)
    msr hcr_el2, x0
    isb

    /* Return to EL1h */
    adr x0, el1_entry
    msr elr_el2, x0
    mov x0, #0x3c5 /* EL1h, all interrupts masked */
    msr spsr_el2, x0
    eret

el1_entry:
    /* Set up stack pointer (1MB above entry point) */
    adr x0, _start
    add x0, x0, #0x00100000
    mov sp, x0

    /* Clear BSS */
    adr x0, __bss_start
    adr x1, __bss_end
clear_bss_loop:
    cmp x0, x1
    b.ge bss_cleared
    str xzr, [x0], #8
    b clear_bss_loop

bss_cleared:
    /* Jump into C main */
    bl loader_main

    /* Hang if main returns */
hang:
    wfe
    b hang
