"""Write a one-voxel NIfTI-1 image with the standard library only.

tests/e2e-smoke.sh runs this at test time so the BIDS fixture needs no committed binary and no
imaging library. The file is a valid single-file NIfTI-1 (.nii.gz): a 348-byte header, a 4-byte
extension flag, and one int16 voxel.

Usage: python3 write-nifti.py <out.nii.gz>
"""
import gzip
import struct
import sys

hdr = bytearray(348)
struct.pack_into("<i", hdr, 0, 348)                         # sizeof_hdr
struct.pack_into("<8h", hdr, 40, 3, 1, 1, 1, 1, 1, 1, 1)    # dim: 3-D, 1x1x1
struct.pack_into("<h", hdr, 70, 4)                          # datatype: int16
struct.pack_into("<h", hdr, 72, 16)                         # bitpix
struct.pack_into("<8f", hdr, 76, 1, 1, 1, 1, 1, 1, 1, 1)    # pixdim (qfac 1), 1 mm voxels
struct.pack_into("<f", hdr, 108, 352)                       # vox_offset
struct.pack_into("<f", hdr, 112, 1)                         # scl_slope
struct.pack_into("<B", hdr, 123, 2 | 8)                     # xyzt_units: mm, s
struct.pack_into("<h", hdr, 252, 1)                         # qform_code: scanner
struct.pack_into("<h", hdr, 254, 1)                         # sform_code: scanner
struct.pack_into("<4f", hdr, 280, 1, 0, 0, 0)               # srow_x
struct.pack_into("<4f", hdr, 296, 0, 1, 0, 0)               # srow_y
struct.pack_into("<4f", hdr, 312, 0, 0, 1, 0)               # srow_z
hdr[344:348] = b"n+1\0"                                     # magic: single-file NIfTI-1

with gzip.open(sys.argv[1], "wb") as f:
    f.write(bytes(hdr) + b"\0\0\0\0" + struct.pack("<h", 100))
