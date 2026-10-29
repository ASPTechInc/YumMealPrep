#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 ASPTechnologies Incorporation
# SPDX-License-Identifier: MIT
"""Turn a hand-written YumMealPrep file into a .backup the app can import,
with its pictures embedded.

The app works offline and never downloads pictures. In a hand-written file,
an item's "image" (and a meal's "nutritionFactImages") can therefore be:

  - a path to a picture on this computer, relative to the file:
        "image": "photos/curry-goat.jpg"
  - a web address, downloaded now by this script:
        "image": "https://upload.wikimedia.org/.../Curry_goat.jpg"
  - a picture bundled with the app, used as it is:
        "image": "assets/images/meals/pelau.webp"

Each picture is prepared the same way the app prepares pictures you add
(at most 1600 pixels, JPEG, no metadata such as location) and embedded
under "images", named by a hash of its contents like the app's own files.
A picture that cannot be read is left out with a warning, and the item
shows the "no picture" placeholder in the app.

Usage:
  scripts/pack-backup.py my-recipes.json [-o yummealprep-backup-<date>-<time>.backup]

The input uses the format in docs/backup-format.md. "format" and "version"
are added if missing, so a file can be as short as:

  {"meals": {"curry-goat": {"name": "Curry Goat", "type": "dinner",
                            "image": "photos/curry-goat.jpg"}}}

Requirements: python3 and Pillow (pip install pillow).
"""
import argparse
import base64
import hashlib
import io
import json
import sys
import urllib.request
from datetime import datetime
from pathlib import Path

MAX_SIDE = 1600  # Keep in step with maxImageSide in lib/services/image_processing.dart.
QUALITY = 85
USER_AGENT = "YumMealPrep-pack-backup/1.0 (https://github.com/ASPTechInc/YumMealPrep)"


def read_picture(value, base):
    if value.startswith(("http://", "https://")):
        request = urllib.request.Request(value, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.read()
    path = (base / value).expanduser()
    return path.read_bytes()


def prepare(data):
    """Resize, turn upright and re-encode as JPEG without metadata."""
    from PIL import Image, ImageOps

    with Image.open(io.BytesIO(data)) as image:
        image = ImageOps.exif_transpose(image).convert("RGB")
        image.thumbnail((MAX_SIDE, MAX_SIDE), Image.LANCZOS)
        out = io.BytesIO()
        image.save(out, "JPEG", quality=QUALITY, optimize=True)  # no exif= drops metadata
        return out.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()

    backup = json.loads(args.input.read_text(encoding="utf-8"))
    backup.setdefault("format", "yummealprep-backup")
    backup.setdefault("version", 1)
    images = backup.setdefault("images", {})
    base = args.input.resolve().parent
    packed, failed = {}, 0

    def pack(value, label):
        nonlocal failed
        if not isinstance(value, str) or not value:
            return None
        if value.startswith(("assets/", "local:", "data:")):
            return value  # already something the app understands
        if value in packed:
            return packed[value]
        try:
            jpeg = prepare(read_picture(value, base))
        except Exception as error:  # noqa: BLE001 - report and carry on
            print(f"warning: {label}: cannot use picture {value!r}: {error}", file=sys.stderr)
            failed += 1
            packed[value] = None
            return None
        source = f"local:images/{hashlib.sha256(jpeg).hexdigest()[:32]}.jpg"
        images[source] = base64.b64encode(jpeg).decode("ascii")
        packed[value] = source
        return source

    for store in ("meals", "recipes"):
        for item_id, item in (backup.get(store) or {}).items():
            label = f"{store}/{item_id}"
            item["image"] = pack(item.get("image"), label)
            if store == "meals" and item.get("nutritionFactImages"):
                item["nutritionFactImages"] = [
                    s for s in (pack(v, label) for v in item["nutritionFactImages"]) if s
                ]

    output = args.output or Path(f"yummealprep-backup-{datetime.now():%Y%m%d-%H%M%S}.backup")
    output.write_text(json.dumps(backup, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    meals, recipes = len(backup.get("meals") or {}), len(backup.get("recipes") or {})
    print(f"{output}: {meals} meals, {recipes} recipes, {len(images)} pictures embedded"
          + (f", {failed} pictures skipped" if failed else ""))


if __name__ == "__main__":
    main()
