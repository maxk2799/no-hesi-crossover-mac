#!/usr/bin/env python3
"""Copy a Wine builtin DLL with its 'Wine builtin DLL' marker blanked, so Wine treats the copy as native."""
import sys

if len(sys.argv) != 3:
    sys.exit("usage: patch-dbghelp.py SOURCE DEST")
data = open(sys.argv[1], "rb").read()
if data[:2] != b"MZ" or data[0x40:0x50] != b"Wine builtin DLL":
    sys.exit("Unexpected file: no Wine builtin marker")
with open(sys.argv[2], "xb") as out:
    out.write(data[:0x40] + bytes(16) + data[0x50:])
print("Added", sys.argv[2].rsplit("/", 1)[-1])
