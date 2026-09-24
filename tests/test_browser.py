"""Lossless browser resource checks; no third-party Python dependencies."""
import csv
import gzip
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from buildfile import build_browser, MASTER_CODELIST


class BrowserBuildTests(unittest.TestCase):
    def assert_roundtrip(self, source):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            manifest = build_browser(source, output)
            rows = []
            for partition in manifest['partitions']:
                payload = (output / partition['file']).read_bytes()
                self.assertEqual(len(payload), partition['bytes'])
                self.assertTrue(partition['file'].startswith(hashlib.sha256(payload).hexdigest()[:24]))
                chunk = json.loads(gzip.decompress(payload))
                self.assertEqual(len(chunk), partition['rows'])
                rows.extend(chunk)
            with source.open(encoding='utf-8-sig', newline='') as handle:
                original = list(csv.reader(handle))
            self.assertEqual(manifest['columns'], original[0])
            self.assertEqual([row[1:] for row in sorted(rows)], original[1:])
            self.assertEqual(manifest['rows'], len(original) - 1)
            before = {p.name: p.read_bytes() for p in output.iterdir()}
            build_browser(source, output)
            self.assertEqual(before, {p.name: p.read_bytes() for p in output.iterdir()})

    def test_master_roundtrip_and_reproducibility(self):
        self.assert_roundtrip(MASTER_CODELIST)

    def test_edge_cases(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'source.csv'
            with source.open('w', encoding='utf-8-sig', newline='') as handle:
                writer = csv.writer(handle)
                writer.writerow(['phenotype_id','phenotype_name','ltc_id','ltc_name','sex','type','body_system','code_type','code','description'])
                row = ['P','Phenotype','L','Condition','either','physical','body','test','000123',' Café, "quoted"\nsecond line ']
                writer.writerows([row, row, row[:8] + ['99999999999999999999', ''], row[:8] + ['', '=literal']])
            self.assert_roundtrip(source)

    def test_reject_inconsistent_metadata(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'bad.csv'
            source.write_text('phenotype_id,phenotype_name,ltc_id,ltc_name,sex,type,body_system,code_type,code,description\nP,A,L,L,either,physical,body,test,1,A\nP,B,L,L,either,physical,body,test,2,B\n')
            with self.assertRaisesRegex(ValueError, 'Conflicting browser metadata'):
                build_browser(source, Path(directory) / 'output')


if __name__ == '__main__':
    unittest.main()
