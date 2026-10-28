#!/usr/bin/env python3
"""Push staged generated files only when their tree differs from the existing proposal.

The caller stages the distribution files over a clean target default branch.
No-op runs leave both the local commit and remote proposal untouched; real
updates use the observed remote revision as an explicit force-with-lease.
"""

import argparse
import os
from pathlib import Path
import subprocess


def git(repo, *args):
    return subprocess.check_output(['git', *args], cwd=repo, text=True).strip()


def publish(repo, branch, message):
    ref = 'refs/heads/' + branch
    git(repo, 'check-ref-format', ref)
    # ls-remote without --exit-code succeeds with empty output for a missing ref,
    # but still propagates authentication/network failures.
    remote = git(repo, 'ls-remote', '--heads', 'origin', ref)
    remote_sha = remote.split()[0] if remote else None
    desired_tree = git(repo, 'write-tree')
    if remote_sha:
        git(repo, 'fetch', '--no-tags', 'origin', ref)
        if git(repo, 'rev-parse', 'FETCH_HEAD') != remote_sha:
            raise RuntimeError('Proposal moved during comparison; retry later')
        if desired_tree == git(repo, 'rev-parse', remote_sha + '^{tree}'):
            print('Generated files already match the existing proposal; no commit or push.')
            return False
    if desired_tree == git(repo, 'rev-parse', 'HEAD^{tree}'):
        print('Generated files already match the default branch; no commit or push.')
        return False
    git(repo, '-c', 'user.name=github-actions[bot]', '-c',
        'user.email=41898282+github-actions[bot]@users.noreply.github.com',
        'commit', '-m', message)
    # An empty expected revision also protects creation against a concurrent push.
    git(repo, 'push', '--force-with-lease=' + ref + ':' + (remote_sha or ''),
        'origin', 'HEAD:' + ref)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('branch')
    parser.add_argument('message')
    args = parser.parse_args()
    pushed = publish(Path.cwd(), args.branch, args.message)
    if output := os.environ.get('GITHUB_OUTPUT'):
        with open(output, 'a', encoding='utf-8') as stream:
            stream.write('pushed=' + str(pushed).lower() + '\n')


if __name__ == '__main__':
    main()
