#!/usr/bin/env python3
"""Exercise proposal idempotency, real updates and lease races against local Git remotes."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import patch

import publish_generated_branch as publisher


SCRIPT = Path(publisher.__file__).resolve()
BRANCH = 'automation/generated-update'


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.remote = self.root / 'remote.git'
        self.work = self.root / 'work'
        self.work.mkdir()
        self.command('git', 'init', '--bare', str(self.remote))
        self.git('init', '--initial-branch=master')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.work / 'generated.txt').write_text('old bindings\n')
        self.git('add', '.')
        self.git('commit', '-m', 'base')
        self.git('remote', 'add', 'origin', str(self.remote))
        self.git('push', 'origin', 'master')
        self.base = self.git('rev-parse', 'HEAD')

    def command(self, *args, **kwargs):
        return subprocess.check_output(args, cwd=self.work, text=True,
                                       stderr=subprocess.PIPE, **kwargs).strip()

    def git(self, *args):
        return self.command('git', *args)

    def revision(self):
        return self.git('ls-remote', 'origin', 'refs/heads/' + BRANCH).split()[0]

    def stage(self, text='new bindings\n'):
        (self.work / 'generated.txt').write_text(text)
        self.git('add', 'generated.txt')

    def run_publisher(self):
        output = self.root / 'output'
        output.unlink(missing_ok=True)
        self.command(sys.executable, str(SCRIPT), BRANCH, 'Generated bindings',
                     env={**os.environ, 'GITHUB_OUTPUT': str(output)})
        return output.read_text()

    def reset_to_base(self):
        # Destructive only inside this test's own temporary fixture checkout.
        self.git('reset', '--hard', self.base)

    def test_first_proposal_is_pushed(self):
        self.stage()
        self.assertEqual(self.run_publisher(), 'pushed=true\n')
        self.assertNotEqual(self.revision(), self.base)

    def test_repeat_preserves_remote_head_and_creates_no_local_commit(self):
        self.stage()
        self.run_publisher()
        previous = self.revision()
        self.reset_to_base()
        self.stage()
        self.assertEqual(self.run_publisher(), 'pushed=false\n')
        self.assertEqual(self.revision(), previous)
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.base)

    def test_changed_output_updates_same_version_branch(self):
        self.stage()
        self.run_publisher()
        previous = self.revision()
        self.reset_to_base()
        self.stage('corrected generator output\n')
        self.assertEqual(self.run_publisher(), 'pushed=true\n')
        self.assertNotEqual(self.revision(), previous)

    def test_real_base_file_change_is_retained(self):
        self.stage()
        self.run_publisher()
        previous = self.revision()
        self.reset_to_base()
        (self.work / 'loader.v').write_text('updated loader\n')
        self.git('add', '.')
        self.git('commit', '-m', 'base update')
        self.stage()
        self.assertEqual(self.run_publisher(), 'pushed=true\n')
        self.assertNotEqual(self.revision(), previous)
        self.assertEqual(self.git('show', 'HEAD:loader.v'), 'updated loader')

    def test_default_branch_noop_does_not_create_a_proposal(self):
        self.assertEqual(self.run_publisher(), 'pushed=false\n')
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/heads/' + BRANCH), '')

    def test_concurrent_remote_update_is_not_overwritten(self):
        self.stage()
        self.run_publisher()
        previous = self.revision()
        self.reset_to_base()
        self.stage('another update\n')
        original_git = publisher.git

        def race(repo, *args):
            if args[0] == 'push':
                self.command('git', '--git-dir', str(self.remote), 'update-ref',
                             'refs/heads/' + BRANCH, self.base, previous)
            return original_git(repo, *args)

        with patch.object(publisher, 'git', side_effect=race):
            with self.assertRaises(subprocess.CalledProcessError):
                publisher.publish(self.work, BRANCH, 'Generated bindings')
        self.assertEqual(self.revision(), self.base)



if __name__ == '__main__':
    unittest.main()
