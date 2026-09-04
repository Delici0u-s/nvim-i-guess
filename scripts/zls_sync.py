#!/usr/bin/env python3
"""
zls_sync.py — ensure a ZLS binary matching the installed Zig version is
available locally, fetching a matching prebuilt from releases.zigtools.org
if needed. Prints the absolute path to a ready-to-use zls binary on stdout.
All diagnostics/progress go to stderr, so callers can safely treat stdout
as "just the path".

Security notes:
- Only ever talks to releases.zigtools.org (manifest) and a small allowlist
  of known build hosts (binary download), both over HTTPS.
- Verifies the SHA-256 checksum the manifest provides before using a binary.
- Extracts archives defensively (rejects path traversal / symlinks).
- Cache directory and binary are written with owner-only permissions to
  reduce risk on shared/multi-user machines.
- A lock file serializes concurrent syncs (e.g. two Neovim instances
  starting at once) so they don't corrupt each other's download.

Exit codes:
  0 success (path printed on stdout)
  1 zig missing / unreadable / bad output
  2 no compatible zls build exists for this zig version
  3 network, checksum, extraction, or locking failure
"""

import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from typing import Optional
from urllib.parse import quote, urlparse

ALLOWED_API_HOST = "releases.zigtools.org"
ALLOWED_DOWNLOAD_HOSTS = {"builds.zigtools.org", "releases.zigtools.org"}
MAX_DOWNLOAD_BYTES = 50 * 1024 * 1024  # generous cap; real builds are a few MB
MAX_MANIFEST_BYTES = 1 * 1024 * 1024
VERSION_RE = re.compile(r"^[0-9][0-9A-Za-z.+_-]{0,63}$")
USER_AGENT = "zls-sync/1.1 (+https://github.com/zigtools/zls)"


def eprint(*a, **kw):
    print(*a, file=sys.stderr, **kw)


def cache_dir() -> Path:
    if os.name == "nt":
        base = os.environ.get("LOCALAPPDATA") or os.path.expanduser("~\\AppData\\Local")
        return Path(base) / "zls-sync"
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Caches" / "zls-sync"
    base = Path(os.environ.get("XDG_CACHE_HOME") or (Path.home() / ".cache"))
    return base / "zls-sync"


def get_zig_version() -> str:
    zig = shutil.which("zig")
    if not zig:
        eprint("zls_sync: 'zig' not found on PATH")
        sys.exit(1)
    try:
        out = subprocess.check_output([zig, "version"], text=True, timeout=10).strip()
    except (subprocess.CalledProcessError, OSError, subprocess.TimeoutExpired) as e:
        eprint(f"zls_sync: couldn't run 'zig version': {e}")
        sys.exit(1)
    if not VERSION_RE.match(out):
        eprint(f"zls_sync: unexpected 'zig version' output: {out!r}")
        sys.exit(1)
    return out


def platform_key() -> str:
    arch_map = {
        "x86_64": "x86_64",
        "amd64": "x86_64",
        "aarch64": "aarch64",
        "arm64": "aarch64",
        "x86": "x86",
        "i386": "x86",
        "i686": "x86",
    }
    os_map = {"linux": "linux", "darwin": "macos", "windows": "windows"}
    arch = arch_map.get(platform.machine().lower())
    osname = os_map.get(platform.system().lower())
    if not arch or not osname:
        eprint(
            f"zls_sync: unsupported platform {platform.system()}/{platform.machine()}"
        )
        sys.exit(3)
    return f"{arch}-{osname}"


def fetch_manifest(zig_version: str, compatibility: str) -> Optional[dict]:
    url = (
        f"https://{ALLOWED_API_HOST}/v1/zls/select-version"
        f"?zig_version={quote(zig_version, safe='')}&compatibility={compatibility}"
    )
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            raw = resp.read(MAX_MANIFEST_BYTES)
    except (urllib.error.URLError, OSError) as e:
        eprint(f"zls_sync: request failed ({compatibility}): {e}")
        return None
    try:
        data = json.loads(raw.decode("utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        eprint(f"zls_sync: invalid JSON from server: {e}")
        return None
    if "version" not in data:
        eprint(f"zls_sync: no '{compatibility}' zls build known for zig {zig_version}")
        return None
    return data


def download(url: str, dest: Path, max_bytes: int):
    parsed = urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in ALLOWED_DOWNLOAD_HOSTS:
        raise ValueError(f"refusing to download from untrusted URL: {url}")
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp, open(dest, "wb") as out:
        total = 0
        while True:
            chunk = resp.read(1024 * 1024)
            if not chunk:
                break
            total += len(chunk)
            if total > max_bytes:
                raise ValueError(f"download exceeded {max_bytes}-byte safety limit")
            out.write(chunk)


def sha256sum(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _within(directory: Path, target: Path) -> bool:
    try:
        target.resolve().relative_to(directory.resolve())
        return True
    except ValueError:
        return False


def safe_extract(archive_path: Path, dest: Path):
    """Extract, rejecting path traversal and symlink/hardlink members."""
    dest = dest.resolve()
    if archive_path.suffix == ".zip":
        with zipfile.ZipFile(archive_path) as zf:
            for name in zf.namelist():
                if not _within(dest, dest / name):
                    raise ValueError(f"unsafe path in archive: {name}")
            zf.extractall(dest)
    else:
        with tarfile.open(archive_path) as tf:
            for member in tf.getmembers():
                if (
                    not _within(dest, dest / member.name)
                    or member.issym()
                    or member.islnk()
                ):
                    raise ValueError(f"unsafe member in archive: {member.name}")
            try:
                tf.extractall(dest, filter="data")  # Python 3.12+ hardened extraction
            except TypeError:
                tf.extractall(dest)  # older Python: our own checks above already ran


def acquire_lock(cdir: Path, timeout: float = 60.0, stale_after: float = 120.0) -> Path:
    lock_path = cdir / ".lock"
    start = time.monotonic()
    while True:
        try:
            fd = os.open(str(lock_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            os.write(fd, str(os.getpid()).encode())
            os.close(fd)
            return lock_path
        except FileExistsError:
            try:
                age = time.time() - lock_path.stat().st_mtime
            except FileNotFoundError:
                continue  # lock disappeared between checks, retry
            if age > stale_after:
                lock_path.unlink(missing_ok=True)
                continue
            if time.monotonic() - start > timeout:
                eprint("zls_sync: another sync appears to be in progress; giving up")
                sys.exit(3)
            time.sleep(0.5)


def release_lock(lock_path: Path):
    lock_path.unlink(missing_ok=True)


def _synced(bin_path: Path, version_file: Path, zig_version: str) -> bool:
    return (
        bin_path.exists()
        and version_file.exists()
        and version_file.read_text().strip() == zig_version
    )


def main():
    zig_version = get_zig_version()
    cdir = cache_dir()
    cdir.mkdir(parents=True, exist_ok=True)
    if os.name != "nt":
        try:
            os.chmod(cdir, 0o700)
        except OSError:
            pass

    bin_name = "zls.exe" if os.name == "nt" else "zls"
    bin_path = cdir / bin_name
    version_file = cdir / "zig_version.txt"

    # Fast path: no network/lock cost when nothing changed.
    if _synced(bin_path, version_file, zig_version):
        print(str(bin_path))
        return

    lock_path = acquire_lock(cdir)
    try:
        # Another process may have just finished while we waited for the lock.
        if _synced(bin_path, version_file, zig_version):
            print(str(bin_path))
            return

        eprint(f"zls_sync: syncing zls for zig {zig_version} ...")
        key = platform_key()
        manifest = fetch_manifest(zig_version, "full") or fetch_manifest(
            zig_version, "only-runtime"
        )
        if manifest is None:
            sys.exit(2)
        if key not in manifest:
            eprint(f"zls_sync: no build for platform '{key}'")
            sys.exit(2)

        artifact = manifest[key]
        tarball_url = artifact["tarball"]
        eprint(f"zls_sync: downloading zls {manifest['version']}")

        tmp_dir = cdir / f"_tmp.{os.getpid()}"
        shutil.rmtree(tmp_dir, ignore_errors=True)
        tmp_dir.mkdir(parents=True)
        archive_path = tmp_dir / tarball_url.rsplit("/", 1)[-1]

        try:
            download(tarball_url, archive_path, MAX_DOWNLOAD_BYTES)

            expected_sum = artifact.get("shasum")
            if expected_sum:
                actual_sum = sha256sum(archive_path)
                if actual_sum.lower() != expected_sum.lower():
                    raise ValueError(
                        f"checksum mismatch (expected {expected_sum}, got {actual_sum})"
                    )
            else:
                eprint(
                    "zls_sync: warning: manifest gave no checksum, skipping verification"
                )

            safe_extract(archive_path, tmp_dir)
        except Exception as e:
            eprint(f"zls_sync: download/extract failed: {e}")
            shutil.rmtree(tmp_dir, ignore_errors=True)
            sys.exit(3)

        extracted_bin = tmp_dir / bin_name
        if not extracted_bin.exists():
            found = [p for p in tmp_dir.rglob(bin_name) if p.is_file()]
            if not found:
                eprint(f"zls_sync: '{bin_name}' not found in extracted archive")
                shutil.rmtree(tmp_dir, ignore_errors=True)
                sys.exit(3)
            extracted_bin = found[0]

        # Atomic-ish install: write alongside the target, then rename over it,
        # so a client spawning zls mid-sync never sees a partial binary.
        tmp_bin = cdir / (bin_name + ".new")
        shutil.move(str(extracted_bin), str(tmp_bin))
        if os.name != "nt":
            tmp_bin.chmod(0o700)
        os.replace(tmp_bin, bin_path)

        tmp_version = cdir / "zig_version.txt.new"
        tmp_version.write_text(zig_version)
        os.replace(tmp_version, version_file)

        shutil.rmtree(tmp_dir, ignore_errors=True)
        print(str(bin_path))
    finally:
        release_lock(lock_path)


if __name__ == "__main__":
    main()
