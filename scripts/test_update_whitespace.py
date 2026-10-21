#!/usr/bin/env python3
"""Keep the updater's whitespace exception limited to the copied Dear ImGui tree."""

from pathlib import Path
import subprocess
import tempfile
import unittest


CHECK = Path(__file__).with_name('check_update_whitespace.sh')


class UpdateWhitespaceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.paths = ['include/imgui/imgui.cpp', 'imgui.v', 'scripts/update_upstream.sh',
                      'include/local.h']
        for name in self.paths:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('baseline\n')
        self.git('init')
        self.git('add', '.')
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 'commit', '-m', 'fixture')

    def git(self, *args):
        return subprocess.run(['git', *args], cwd=self.root, check=True,
                              capture_output=True, text=True)

    def check(self):
        return subprocess.run(['bash', str(CHECK)], cwd=self.root,
                              capture_output=True, text=True)

    def test_copied_upstream_whitespace_is_preserved(self):
        path = self.root / self.paths[0]
        path.write_text('upstream text with spaces  \n\n')
        original = subprocess.run(['git', 'diff', '--check'], cwd=self.root,
                                  capture_output=True, text=True)
        self.assertNotEqual(original.returncode, 0)
        self.assertEqual(self.check().returncode, 0)
        self.assertEqual(path.read_text(), 'upstream text with spaces  \n\n')

    def test_maintained_and_generated_files_still_fail(self):
        for name in self.paths[1:]:
            with self.subTest(path=name):
                path = self.root / name
                path.write_text('invalid trailing spaces  \n')
                result = self.check()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(name, result.stdout)
                path.write_text('baseline\n')

    def test_clean_diff_passes(self):
        self.assertEqual(self.check().returncode, 0)


if __name__ == '__main__':
    unittest.main()
