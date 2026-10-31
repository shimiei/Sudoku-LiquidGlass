#!/usr/bin/env python3
"""Prints the LC_BUILD_VERSION of a Mach-O: platform, minos and *linked SDK*.

The linked SDK version is what decides whether iOS 26 renders the new
Liquid Glass design for an app, so it is worth checking on every build.
"""
import struct
import sys


def v(n):
    return "%d.%d.%d" % (n >> 16, (n >> 8) & 0xFF, n & 0xFF)


def main(path):
    with open(path, "rb") as f:
        data = f.read()
    magic = struct.unpack_from("<I", data, 0)[0]
    if magic != 0xFEEDFACF:
        print("not a 64-bit little-endian Mach-O")
        return 1
    cputype, _, _, ncmds, _, _ = struct.unpack_from("<iiIIII", data, 4)
    print("cputype  : 0x%x (%s)" % (cputype, {0x0100000C: "arm64"}.get(cputype, "?")))
    off = 32
    for _ in range(ncmds):
        cmd, size = struct.unpack_from("<II", data, off)
        if cmd == 0x32:  # LC_BUILD_VERSION
            platform, minos, sdk = struct.unpack_from("<III", data, off + 8)
            names = {1: "macOS", 2: "iOS", 3: "tvOS", 4: "watchOS", 6: "macCatalyst", 7: "iOS-sim"}
            print("platform : %s" % names.get(platform, platform))
            print("minos    : %s" % v(minos))
            print("sdk      : %s   <-- 编译器/链接使用的 SDK，iOS 26 起决定是否用新设计" % v(sdk))
        elif cmd == 0x25:  # LC_VERSION_MIN_IPHONEOS
            minos, sdk = struct.unpack_from("<II", data, off + 8)
            print("LC_VERSION_MIN_IPHONEOS minos %s sdk %s" % (v(minos), v(sdk)))
        off += size
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
