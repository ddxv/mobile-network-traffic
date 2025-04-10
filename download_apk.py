#!/usr/bin/env python
"""Download APK files from with Python.

Author: James O'Claire

This script scrapes https://apkpure.com to get the apk download link
"""

import argparse
import pathlib
import os

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



def download(store_id: str, do_redownload: bool = False) -> str:
    """Download the apk file.

    store_id: str the id of the android apk

    """

    check_apk_dir_created()
    filepath = pathlib.Path(APKS_DIR, f"{store_id}.apk")
    exists = filepath.exists()
    if exists:
        if not do_redownload:
            return filepath.suffix

    r = requests.get(
        URL.format(store_id=store_id),
        headers={
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0",
        },
        stream=True,
        timeout=10,
    )
    if r.status_code == 200:
        extension = ".apk"  # default fallback

        content_disposition = r.headers.get("Content-Disposition", "")
        if "filename=" in content_disposition:
            filename = content_disposition.split("filename=")[-1].strip("\"'")
            ext = pathlib.Path(filename).suffix
            if ext:
                extension = ext

        filepath = pathlib.Path(APKS_DIR, f"{store_id}{extension}")

        with filepath.open("wb") as file:
            for chunk in r.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    file.write(chunk)
    else:
        print(f"status code: {r.status_code} {r.text[0:25]}")
        raise requests.exceptions.HTTPError
    return extension



def main(args: argparse.Namespace) -> None:
    """Download APK to local directory and exit."""
    check_apk_dir_created()
    store_id = args.store_id
    print(f"Start download {store_id}")
    filepath = pathlib.Path(APKS_DIR, f"{store_id}.apk")
    exists = filepath.exists()
    if exists:
        print(f"apk already exists {filepath=}")
        ext = 'apk'
    else:
        print(f"download from apkpure {store_id=}")
        ext = download(store_id=store_id)
    if ext == '.xapk':
        os.system(f"unzip apks/{store_id}{ext} -d myunzip")
        # output is myunzip_merged.apk
        os.system('rm -rf myunzip/*')
        os.system("java -jar APKEditor.jar m -i myunzip/")
        os.system(f"mv myunzip_merged.apk apks/{store_id}.apk")
        os.system('rm -rf myunzip/*')
    else:
        pass




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
