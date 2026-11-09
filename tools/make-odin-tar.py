#!/usr/bin/env python3
"""
Samsung Odin .tar.md5 Packager for SM8250 (r8q)
Packages boot.img (and optional recovery.img/dtbo.img) into an Odin-flashable .tar.md5 archive.
"""

import sys
import os
import tarfile
import hashlib
import argparse

def create_odin_tar(files_to_pack, output_path):
    print(f"[*] Packaging Odin flashable archive: {output_path}")
    tar_path = output_path.replace('.md5', '')
    if not tar_path.endswith('.tar'):
        tar_path += '.tar'

    with tarfile.open(tar_path, "w") as tar:
        for file_path in files_to_pack:
            if not os.path.exists(file_path):
                print(f"[-] Error: Input file '{file_path}' does not exist.")
                sys.exit(1)
            arcname = os.path.basename(file_path)
            # Ensure name inside tar is boot.img
            if 'boot' in arcname and not arcname == 'boot.img':
                arcname = 'boot.img'
            print(f"  -> Adding {arcname} ({os.path.getsize(file_path)} bytes)...")
            tar.add(file_path, arcname=arcname)

    print("[*] Calculating MD5 checksum...")
    md5_hash = hashlib.md5()
    with open(tar_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096 * 1024), b""):
            md5_hash.update(chunk)
    
    checksum = md5_hash.hexdigest()
    tar_filename = os.path.basename(tar_path)
    print(f"[+] MD5: {checksum}  {tar_filename}")

    # Append MD5 footer as required by Samsung Odin
    with open(tar_path, "ab") as f:
        footer = f"\n{checksum}  {tar_filename}\n".encode('utf-8')
        f.write(footer)

    final_path = tar_path if tar_path.endswith('.md5') else tar_path + '.md5'
    if final_path != tar_path:
        if os.path.exists(final_path):
            os.remove(final_path)
        os.rename(tar_path, final_path)

    print(f"[OK] Successfully created Odin package: {final_path}")
    print(f"    You can flash this file in Odin using the 'AP' slot in Download Mode.")
    return final_path

def main():
    parser = argparse.ArgumentParser(description="Create Samsung Odin .tar.md5 flashable archive")
    parser.add_argument('inputs', nargs='+', help="Input files (e.g. boot.img recovery.img dtbo.img)")
    parser.add_argument('-o', '--output', default='out/boot_AP.tar.md5', help="Output .tar.md5 path")

    args = parser.parse_args()
    create_odin_tar(args.inputs, args.output)

if __name__ == '__main__':
    main()
