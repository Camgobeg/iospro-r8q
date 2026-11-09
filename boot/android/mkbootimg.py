#!/usr/bin/env python3
"""
Simple Android boot.img packager supporting Header v1 and v2 for Snapdragon devices.
"""

import argparse
import struct
import os
import sys

BOOT_MAGIC = b'ANDROID!'

def pad_file(f, page_size):
    pad = (page_size - (f.tell() % page_size)) % page_size
    f.write(b'\x00' * pad)

def write_bootimg(args):
    kernel_data = open(args.kernel, 'rb').read() if args.kernel and os.path.exists(args.kernel) else b''
    ramdisk_data = open(args.ramdisk, 'rb').read() if args.ramdisk and os.path.exists(args.ramdisk) else b''
    dtb_data = open(args.dtb, 'rb').read() if args.dtb and os.path.exists(args.dtb) else b''

    page_size = args.pagesize

    kernel_size = len(kernel_data)
    ramdisk_size = len(ramdisk_data)
    second_size = 0
    dtb_size = len(dtb_data)

    cmdline = args.cmdline.encode('utf-8')[:512].ljust(512, b'\x00')

    with open(args.output, 'wb') as f:
        # Header v2 struct format
        header = struct.pack(
            '8s10I512s32s1024s2I',
            BOOT_MAGIC,
            kernel_size,
            args.base + args.kernel_offset,
            ramdisk_size,
            args.base + args.ramdisk_offset,
            second_size,
            args.base + args.second_offset,
            args.base + args.tags_offset,
            page_size,
            args.header_version,
            0, # os_version
            cmdline,
            b'\x00' * 32, # id
            b'\x00' * 1024, # extra cmdline
            0, # recovery dtbo size
            0  # recovery dtbo offset
        )
        # Append dtb size and offset for header v2
        header += struct.pack('IQ', dtb_size, args.base + args.dtb_offset)
        f.write(header)
        pad_file(f, page_size)

        if kernel_size > 0:
            f.write(kernel_data)
            pad_file(f, page_size)

        if ramdisk_size > 0:
            f.write(ramdisk_data)
            pad_file(f, page_size)

        if dtb_size > 0:
            f.write(dtb_data)
            pad_file(f, page_size)

    print(f"[✓] Created Android boot image: {args.output} ({os.path.getsize(args.output)} bytes)")

def main():
    parser = argparse.ArgumentParser(description="Pack Android boot.img")
    parser.add_argument('--kernel', required=True)
    parser.add_argument('--ramdisk', default='')
    parser.add_argument('--dtb', default='')
    parser.add_argument('--cmdline', default='console=simplefb -v debug=0x14e cs_enforcement=0')
    parser.add_argument('--base', type=lambda x: int(x, 0), default=0x00000000)
    parser.add_argument('--kernel_offset', type=lambda x: int(x, 0), default=0x00008000)
    parser.add_argument('--ramdisk_offset', type=lambda x: int(x, 0), default=0x01000000)
    parser.add_argument('--second_offset', type=lambda x: int(x, 0), default=0x00f00000)
    parser.add_argument('--tags_offset', type=lambda x: int(x, 0), default=0x00000100)
    parser.add_argument('--dtb_offset', type=lambda x: int(x, 0), default=0x01f00000)
    parser.add_argument('--pagesize', type=lambda x: int(x, 0), default=4096)
    parser.add_argument('--header_version', type=int, default=2)
    parser.add_argument('-o', '--output', required=True)

    args = parser.parse_args()
    write_bootimg(args)

if __name__ == '__main__':
    main()
