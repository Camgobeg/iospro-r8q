#!/usr/bin/env python3
"""
Apple IPSW / DMG RootFS and Kernelcache Extractor for iospro-r8q
Extracts kernelcache, devicetree, and root filesystem DMG from Apple IPSWs.
"""

import sys
import zipfile
import plistlib
import os
import argparse

def inspect_ipsw(ipsw_path):
    print(f"[*] Inspecting IPSW: {ipsw_path}")
    if not zipfile.is_zipfile(ipsw_path):
        print(f"[-] Error: {ipsw_path} is not a valid zip/ipsw archive.")
        sys.exit(1)

    with zipfile.ZipFile(ipsw_path, 'r') as z:
        manifest_data = z.read('BuildManifest.plist')
        manifest = plistlib.loads(manifest_data)
        
        product_version = manifest.get('ProductVersion', 'Unknown')
        product_build = manifest.get('ProductBuildVersion', 'Unknown')
        print(f"[+] iOS / iPadOS Version: {product_version} ({product_build})")

        print("[*] Available components:")
        for item in z.namelist():
            if item.endswith('.dmg') or 'kernelcache' in item or 'DeviceTree' in item:
                info = z.getinfo(item)
                print(f"    - {item} ({info.file_size / (1024*1024):.2f} MB)")

def extract_component(ipsw_path, target_pattern, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    with zipfile.ZipFile(ipsw_path, 'r') as z:
        for item in z.namelist():
            if target_pattern in item:
                print(f"[*] Extracting {item} -> {output_dir}")
                z.extract(item, output_dir)

def main():
    parser = argparse.ArgumentParser(description="Apple IPSW Component Extractor")
    parser.add_argument('ipsw', help="Path to input .ipsw file")
    parser.add_argument('--list', action='store_true', help="List contents")
    parser.add_argument('--extract-kernel', action='store_true', help="Extract kernelcache")
    parser.add_argument('--extract-all', action='store_true', help="Extract kernel, dtb and dmg")
    parser.add_argument('-o', '--output', default='build/ipsw_out', help="Output directory")

    args = parser.parse_args()
    if args.list:
        inspect_ipsw(args.ipsw)
    elif args.extract_kernel:
        extract_component(args.ipsw, 'kernelcache', args.output)
    elif args.extract_all:
        extract_component(args.ipsw, '.dmg', args.output)
        extract_component(args.ipsw, 'kernelcache', args.output)
    else:
        inspect_ipsw(args.ipsw)

if __name__ == '__main__':
    main()
