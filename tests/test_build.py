from pathlib import Path
import os
import subprocess
import sys
import unittest
from unittest.mock import patch
from build import ROOT,bundle


class BuildTests(unittest.TestCase):
    def test_luna_receives_ascii_relative_filenames(self):
        from build import main
        with patch("sys.argv",["build.py","--luna","mock-luna.exe"]):
            with patch("build.subprocess.run") as run:
                main()
        args, kwargs = run.call_args
        self.assertEqual(args[0][1:],["bitling.lua","bitling.tns"])
        self.assertEqual(kwargs["cwd"],ROOT/"build")

    def test_non_ascii_workspace_build_with_legacy_console_encoding(self):
        env=dict(os.environ,PYTHONIOENCODING="cp1252")
        result=subprocess.run([sys.executable,str(ROOT/"tools/build.py")],
                              cwd=ROOT,env=env,capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr.decode("ascii",errors="replace"))
        self.assertTrue((ROOT/"build/bitling.lua").is_file())

    def test_bundle_is_deterministic_compact_and_has_no_device_filesystem_calls(self):
        source=bundle()
        self.assertEqual(source,bundle())
        self.assertLess(len(source.encode("utf-8")),128*1024)
        for token in ("io.open(","os.execute(","math.eval(","var.store(","loadstring("):
            self.assertNotIn(token,source)
        self.assertIn('platform.apiLevel = "2.0"',source)
