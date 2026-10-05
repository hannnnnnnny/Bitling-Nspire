import hashlib
import struct
import unittest
from build import ROOT,bundle


class DistributionTests(unittest.TestCase):
    def test_distribution_source_matches_modules_and_checksums(self):
        directory=ROOT/"dist"
        source=(directory/"bitling.lua").read_text("utf-8")
        self.assertEqual(source,bundle())
        for line in (directory/"SHA256SUMS").read_text("ascii").splitlines():
            expected,name=line.split("  ",1)
            self.assertEqual(hashlib.sha256((directory/name).read_bytes()).hexdigest(),expected)

    def test_luna_document_container_structure(self):
        data=(ROOT/"dist/bitling.tns").read_bytes()
        self.assertTrue(data.startswith(b"*TIMLP0500"))
        tail=struct.unpack_from("<4sHHHHIIH",data,len(data)-22)
        self.assertEqual(tail[0],b"TIPD")
        self.assertEqual(tail[3:5],(2,2))
        self.assertEqual(tail[5]+tail[6],len(data)-22)
        offset=tail[6]
        names=[]
        for _ in range(2):
            entry=struct.unpack_from("<4s6H3I5H2I",data,offset)
            self.assertEqual(entry[0],b"PK\x01\x02")
            self.assertEqual(entry[4],13)
            names.append(data[offset+46:offset+46+entry[10]].decode("ascii"))
            self.assertLess(entry[16],tail[6])
            offset+=46+entry[10]+entry[11]+entry[12]
        self.assertEqual(names,["Document.xml","Problem1.xml"])
        self.assertLess(len(data),128*1024)
