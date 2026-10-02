#!/usr/bin/env python3
"""Fetch the pinned AccessKit release and build the Linux compatibility fixes."""
import argparse
import hashlib
import io
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent.parent
VERSION = '0.23.1'
RELEASE_SHA256 = '35b7ca8a6f1e038b5da35e1e9e5a0adaed9bfcf21e1496d29598fbbadcc7043f'
CRATES = {
    'accesskit_atspi_common-0.21.0': '52c182f9c282ac9c5638d876d551d15e5f7d397ec263349a0c6a2b61595dd5e4',
    'accesskit_unix-0.24.0': '202f24df034a7476d07b7f74284de84f6d62aabd858dbe7ee9cad3b7ad6f8f9d',
}
ANDROID_CRATE = 'accesskit_android-0.9.0'
ANDROID_SHA256 = '726162393d59ecdc12cce5eccbd75eb08838e841ed48a583ecc9ad95c5fe748e'


def download(url, path, expected):
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(url) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != expected:
            raise RuntimeError(f'Checksum mismatch: {url}')
        path.write_bytes(data)
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != expected:
        raise RuntimeError(f'Checksum mismatch: {path}')
    return data


def patch(directory, path):
    check = subprocess.run(['git', 'apply', '--check', str(path)], cwd=directory,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if check.returncode == 0:
        subprocess.run(['git', 'apply', str(path)], cwd=directory, check=True)
    else:
        # An already applied patch is valid; a partially applied/changed source is not.
        subprocess.run(['git', 'apply', '--reverse', '--check', str(path)], cwd=directory, check=True)


def prepare(linux, android=False):
    base = ROOT / '.dependencies/accesskit'
    release = base / f'accesskit-c-{VERSION}'
    data = download(f'https://github.com/AccessKit/accesskit-c/releases/download/{VERSION}/accesskit-c-{VERSION}.zip',
                    base / f'accesskit-c-{VERSION}.zip', RELEASE_SHA256)
    if not release.exists():
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            archive.extractall(base)
    if linux or android:
        sources = ROOT / 'build/accesskit-source'
        selected = dict(CRATES) if linux else {}
        if android:
            selected[ANDROID_CRATE] = ANDROID_SHA256
        patch_paths = []
        if linux:
            patch_paths += [ROOT / 'patches/accesskit/linux-atspi.patch',
                            ROOT / 'patches/accesskit/linux-focus-cache.patch']
        if android:
            patch_paths += [ROOT / 'patches/accesskit/android-set-text.patch']
        revision = hashlib.sha256(b''.join(path.read_bytes() for path in patch_paths)).hexdigest()
        refresh_sources = any(
            not (sources / crate / '.codex-patches.sha256').exists() or
            (sources / crate / '.codex-patches.sha256').read_text() != revision
            for crate in selected)
        for crate, sha in selected.items():
            name, version = crate.rsplit('-', 1)
            data = download(f'https://static.crates.io/crates/{name}/{crate}.crate', base / f'{crate}.crate', sha)
            # Rebuild owned extracted sources when the patch stack changes.
            # Layered patches cannot be reverse-checked independently once a
            # later patch modifies the same lines as an earlier patch.
            extracted = sources / crate
            marker = extracted / '.codex-patches.sha256'
            if refresh_sources:
                if extracted.exists():
                    shutil.rmtree(extracted)
                with tarfile.open(fileobj=io.BytesIO(data)) as archive:
                    archive.extractall(sources, filter='data')
        if linux and refresh_sources:
            patch(sources, ROOT / 'patches/accesskit/linux-atspi.patch')
            patch(sources, ROOT / 'patches/accesskit/linux-focus-cache.patch')
        if android and refresh_sources:
            patch(sources, ROOT / 'patches/accesskit/android-set-text.patch')
        for crate in selected:
            (sources / crate / '.codex-patches.sha256').write_text(revision)
        manifest = release / 'Cargo.toml'
        text = manifest.read_text()
        if '[patch.crates-io]' not in text:
            text += '\n[patch.crates-io]\n'
        for crate in selected:
            name, _ = crate.rsplit('-', 1)
            if f'{name} = {{ path =' not in text:
                text += f'{name} = {{ path = "../../../build/accesskit-source/{crate}" }}\n'
        manifest.write_text(text)
        if linux:
            patch(release, ROOT / 'patches/accesskit/cargo-lock.patch')
        if android:
            patch(release, ROOT / 'patches/accesskit/android-cargo-lock.patch')
        if linux:
            subprocess.run(['cargo', 'build', '--locked', '--release', '-j', '2', '--manifest-path', str(manifest)], check=True)
    print(release)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prebuilt', action='store_true', help='Download only; skip the Linux source build.')
    parser.add_argument('--android-source', action='store_true', help='Prepare the Android compatibility source patch.')
    args = parser.parse_args()
    prepare(platform.system() == 'Linux' and not args.prebuilt and not args.android_source, args.android_source)
