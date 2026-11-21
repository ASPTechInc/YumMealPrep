#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 ASPTechnologies Incorporation
# SPDX-License-Identifier: MIT
"""Replace (or add) the picture of a meal or recipe inside a .backup file.

The picture is cropped to 4:3, resized to 1024x768 and saved as WebP, the
same as the photos made by scripts/fetch-photos.py, then written into the
backup's "images" section. Importing the backup puts it on the device.

Usage:

  scripts/replace-backup-photo.py BACKUP NAME PICTURE [options]

  BACKUP   the .backup file to change (it is changed in place)
  NAME     the meal or recipe, as it appears in the app (case does not matter)
  PICTURE  the new picture: a .png, .jpg or .webp file

Options:

  --meal / --recipe   say which one you mean when a meal and a recipe have
                      the same name (for example Callaloo Soup)
  --crop L T R B      crop to these fractions of the picture instead of the
                      centred 4:3 crop, e.g. --crop 0 0.1 1 0.85
  -o FILE             write the result to FILE and leave BACKUP as it is

Example:

  scripts/replace-backup-photo.py \\
      assets/data/yummealprep-backup-20261028-213707-with-pictures.backup \\
      "Curry Goat" ~/Downloads/curry-goat.png

Steps to replace a picture:

  1. Keep a copy of the backup first. It is the only copy of most pictures.
  2. Run the script as above. It says which entry it changed.
  3. If the photo is from Wikimedia Commons, update its entry in
     scripts/photo-sources.json (source, file, author, licence, spdx) and run
     `scripts/fetch-photos.py credits`, so the app credits the right person.
     Use only CC0, public domain, CC BY or CC BY-SA photos.
  4. Import the backup in the app with "Replace everything" to check it.

Requirements: python3 and Pillow (pip install pillow).
"""
import argparse
import base64
import io
import json
import re
import sys
from pathlib import Path

from PIL import Image, ImageOps

# Keep in step with SIZE and QUALITY in scripts/fetch-photos.py.
WIDTH, HEIGHT, QUALITY = 1024, 768, 78


def prepare(path, crop=None):
    image = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
    width, height = image.size
    if crop:
        left, top, right, bottom = crop
        image = image.crop((round(left * width), round(top * height), round(right * width), round(bottom * height)))
    # Fill the frame rather than letterbox it, as the app's cards are 4:3.
    image = ImageOps.fit(image, (WIDTH, HEIGHT), Image.LANCZOS)
    out = io.BytesIO()
    # Saving from a fresh RGB image leaves out EXIF, such as GPS location.
    image.save(out, "WEBP", quality=QUALITY, method=6)
    return out.getvalue()


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower().replace("&", "and")).strip("-")


def main():
    parser = argparse.ArgumentParser(usage=__doc__, add_help=False)
    parser.add_argument("backup", type=Path)
    parser.add_argument("name")
    parser.add_argument("picture", type=Path)
    kind = parser.add_mutually_exclusive_group()
    kind.add_argument("--meal", dest="kind", action="store_const", const="meals")
    kind.add_argument("--recipe", dest="kind", action="store_const", const="recipes")
    parser.add_argument("--crop", nargs=4, type=float, metavar=("L", "T", "R", "B"))
    parser.add_argument("-o", dest="output", type=Path)
    if "-h" in sys.argv or "--help" in sys.argv or len(sys.argv) < 4:
        sys.exit(__doc__)
    args = parser.parse_args()

    data = json.loads(args.backup.read_text(encoding="utf-8"))
    if data.get("format") != "yummealprep-backup":
        sys.exit(f"{args.backup} is not a YumMealPrep backup.")

    stores = [args.kind] if args.kind else ["meals", "recipes"]
    matches = [
        (store, item)
        for store in stores
        for item in data.get(store, [])
        if item.get("name", "").strip().lower() == args.name.strip().lower()
    ]
    if not matches:
        sys.exit(f'No meal or recipe called "{args.name}" in {args.backup}.')
    if len(matches) > 1:
        sys.exit(f'"{args.name}" is both a meal and a recipe. Add --meal or --recipe to choose.')
    store, item = matches[0]

    # Reuse the item's picture name so nothing else has to change. A name
    # that is not WebP (a photo added in the app is JPEG) gets a new one.
    key = item.get("image") or ""
    if not key.endswith(".webp"):
        key = f"assets/images/{store}/{slug(item['name'])}.webp"
        item["image"] = key

    images = data.setdefault("images", {})
    replacing = key in images
    images[key] = base64.b64encode(prepare(args.picture, args.crop)).decode("ascii")

    # One picture can belong to several items. They all get the new one.
    sharing = [
        other["name"]
        for s in ("meals", "recipes")
        for other in data.get(s, [])
        if other is not item and (other.get("image") == key or key in other.get("nutritionFactImages", []))
    ]

    output = args.output or args.backup
    output.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f'{"Replaced" if replacing else "Added"} the picture of {item["name"]} ({store[:-1]}): {key}')
    if sharing:
        print("The same picture is also used by: " + ", ".join(sharing))
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
