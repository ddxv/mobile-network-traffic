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
ANDROID_SDK = pathlib.Path("~/Android/Sdk/build-tools/35.0.0")


def check_apk_dir_created() -> None:
    """Create if not exists for apks directory."""
    dirs = [APKS_DIR]
    for _dir in dirs:
        if not pathlib.Path.exists(_dir):
            print("creating apks directory")
            pathlib.Path.mkdir(_dir, exist_ok=True)


def check_dirs_and_file_exists(store_id:str, do_redownload:bool = False)->str|None:
    apk_filepath = pathlib.Path(APKS_DIR, f"{store_id}.apk")
    xapk_filepath = pathlib.Path(APKS_DIR, f"{store_id}.xapk")
    exists = apk_filepath.exists()
    xapk_exists = xapk_filepath.exists()
    if exists:
        if not do_redownload:
            print(f"{apk_filepath=} Exists")
            return apk_filepath.suffix
    if xapk_exists:
        if not do_redownload:
            print(f"{xapk_filepath=} Exists")
            return xapk_filepath.suffix

def download(store_id: str) -> str:
    """Download the apk file.

    store_id: str the id of the android apk

    """
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

        apk_filepath = pathlib.Path(APKS_DIR, f"{store_id}{extension}")

        with apk_filepath.open("wb") as file:
            for chunk in r.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    file.write(chunk)
    else:
        print(f"status code: {r.status_code} {r.text[0:25]}")
        raise requests.exceptions.HTTPError
    return extension



def main(args: argparse.Namespace) -> None:
    """Download APK to local directory and exit."""
    store_id = args.store_id
    print(f"Start getting APK for {store_id}")
    ext = check_dirs_and_file_exists(store_id)
    if ext:
        print(f"apk already exists {ext=}")
    else:
        ext = download(store_id=store_id)
    if ext == '.xapk':
        pass
        # output is apks/com.example_merged.apk
        os.system(f"java -jar APKEditor.jar m -i apks/{store_id}.xapk")
        # APKEditor merged APKs must be signed to install
        apk_path = pathlib.Path(APKS_DIR, f"{store_id}.apk")
        merged_apk_path = pathlib.Path(APKS_DIR, f"{store_id}_merged.apk")
        os.system(f"{ANDROID_SDK}/apksigner sign --ks ~/.android/debug.keystore  --ks-key-alias androiddebugkey   --ks-pass pass:android   --key-pass pass:android   --out {apk_path}  {merged_apk_path}")
    else:
        pass
    print(f"Finished getting APK for {store_id}")
    



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
