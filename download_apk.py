#!/usr/bin/env python
"""Download APK files from with Python.

Author: James O'Claire

This script scrapes https://apkpure.com to get the apk download link
"""

import argparse
import pathlib

import requests

URL = "https://d.apkpure.com/b/APK/{store_id}?version=latest"
APK_DIR = "apks"


def download(store_id: str) -> None:
    """Download the apk file.

    store_id: str the id of the android apk

    """
    r = requests.get(
        URL.format(store_id=store_id),
        headers={
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.7.5 (KHTML, like Gecko) "
            "Version/9.1.2 Safari/601.7.5 ",
        },
        stream=True,
        timeout=10,
    )
    filepath = pathlib.Path(APK_DIR + "/" + store_id + ".apk")
    with filepath.open("wb") as file:
        for chunk in r.iter_content(chunk_size=1024):
            if chunk:
                file.write(chunk)


def main(args: argparse.Namespace) -> None:
    """Download APK to local directory and exit."""
    store_id = args.store_id
    print(f"Start {store_id}")
    path = pathlib.Path(APK_DIR + f"/{store_id}" + ".apk")
    exists = path.exists()
    if exists:
        print(f"apk already exists {path=}")
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
