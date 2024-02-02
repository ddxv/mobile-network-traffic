#!/usr/bin/env python
"""Download APK files from with Python.

Author: James O'Claire

This script scrapes https://apkpure.com to get the apk download link
"""

import argparse
import pathlib

import requests

URL = "https://d.apkpure.net/b/APK/{store_id}?version=latest"
MODULE_DIR = pathlib.Path(__file__).resolve().parent
APKS_DIR = pathlib.Path(MODULE_DIR, "apks")


def check_apk_dir_created() -> None:
    """Create if not exists for apks directory."""
    dirs = [APKS_DIR]
    for _dir in dirs:
        if not pathlib.Path.exists(_dir):
            print("creating apks directory")
            pathlib.Path.mkdir(_dir, exist_ok=True)


def download(store_id: str) -> None:
    """Download the apk file.

    store_id: str the id of the android apk

    """
    r = requests.get(
        URL.format(store_id=store_id),
        headers={
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.7.5 (KHTML, like Gecko) Version/9.1.2 Safari/601.7.5 ",
        },
        stream=True,
        timeout=10,
    )
    filepath = pathlib.Path(APKS_DIR, f"{store_id}.apk")
    with filepath.open("wb") as file:
        for chunk in r.iter_content(chunk_size=1024):
            if chunk:
                file.write(chunk)


def main(args: argparse.Namespace) -> None:
    """Download APK to local directory and exit."""
    check_apk_dir_created()
    store_id = args.store_id
    print(f"Start download {store_id}")
    filepath = pathlib.Path(APKS_DIR, f"{store_id}.apk")
    exists = filepath.exists()
    if exists:
        print(f"apk already exists {filepath=}")
    else:
        print(f"download from apkpure {store_id=}")
        download(store_id=store_id)


def parse_args() -> argparse.Namespace:
    """Check passed args.

    will check for command line --store-id in the form of com.example.app
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-s",
        "--store-id",
        help="Store id to download, ie -s 'org.moire.opensudoku'",
    )
    args, leftovers = parser.parse_known_args()
    return args


if __name__ == "__main__":
    args = parse_args()
    main(args)
