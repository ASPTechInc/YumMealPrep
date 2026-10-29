#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 ASPTechnologies Incorporation
# SPDX-License-Identifier: MIT
"""Convert the old Firebase (Cloud Firestore) export into YumMealPrep data.

The output uses the app's own backup format (docs/backup-format.md), which
is what the app imports and what its local sembast database stores: one
record per meal or recipe, keyed by id.

What changes on the way:
- Firestore labels such as "Lunch" become the app's type names ("lunch").
- "N/A" placeholders become empty values.
- Free-text times ("1h 25mins", "15-20mins") become whole minutes, using the
  upper end of a range, and servings ("6-8", "10 bowls") become numbers.
- Pictures stored on Firebase Storage are replaced by the bundled, freely
  licensed photos listed in scripts/photo-sources.json.
- Nutrition-label photos on Firebase Storage are dropped, because they can
  no longer be downloaded.
- searchKeywords, category, isItemSelected and isMealInMealPlanner are
  dropped. Search now works on the text itself (lib/utils/search.dart).

Usage:
  scripts/convert-firestore-export.py assets/data/firestore-export.json [-o FILE]

Writes a .backup file (plain JSON) with every meal, recipe and planned
meal, named like the app's own exports
(yummealprep-backup-20261028-213707.backup) unless -o is given. Load it
with "Import data" in the app's side menu. Backups are personal, so
*.backup is ignored by git.

The bundled sample data (assets/data/seed.json) is a small, hand-picked
selection kept in the same format.
"""
import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PHOTOS = ROOT / "scripts" / "photo-sources.json"

MONTHS = {m: i for i, m in enumerate(
    ["January", "February", "March", "April", "May", "June", "July",
     "August", "September", "October", "November", "December"], 1)}

# Names tidied for display. Ids are kept, so a re-import replaces, not
# duplicates, these items.
NAMES = {
    "Spaghetti & Meat Balls": "Spaghetti & Meatballs",
    "Steam Vegetables": "Steamed Vegetables",
    "Vegetable rice": "Vegetable Rice",
    "White rice (Plain)": "White Rice (Plain)",
    "Mash Potato Salad": "Mashed Potato Salad",
}

# Typos and spellings fixed in all text (British English, as in the app).
TEXT_FIXES = [
    (r"\bTumeric\b", "Turmeric"), (r"\btumeric\b", "turmeric"),
    (r"\badd add\b", "add"), (r"\bmice meat\b", "mince meat"),
    (r"\badvocado\b", "avocado"), (r"\bflavorful\b", "flavourful"),
    (r"\bflavor\b", "flavour"), (r"\bcolorful\b", "colourful"),
    (r"\bit's fragrance\b", "its fragrance"), (r"\btps\b", "tsp"),
    (r"\s+,", ","), (r"\s{2,}", " "),
]


def clean(text):
    text = (text or "").replace(" ", " ").strip()
    for pattern, replacement in TEXT_FIXES:
        text = re.sub(pattern, replacement, text)
    return text.strip()


def clean_list(items):
    return [c for c in (clean(i) for i in items or []) if c and c.upper() != "N/A"]


def not_applicable(value):
    value = clean(value)
    return "" if value.upper() in ("N/A", "NA", "NONE") else value


def meal_type(label):
    return clean(label).lower() or "lunch"


def minutes(text):
    """'1h 25mins' -> 85, '15-20mins' -> 20, '3hours' -> 180, '' -> None."""
    text = clean(text).lower()
    if not text:
        return None
    text = re.sub(r"(\d+)\s*-\s*(\d+)", r"\2", text)  # upper end of a range
    hours = re.search(r"(\d+)\s*h", text)
    mins = re.search(r"(\d+)\s*m", text)
    if hours or mins:
        return (int(hours.group(1)) * 60 if hours else 0) + (int(mins.group(1)) if mins else 0)
    number = re.search(r"\d+", text)
    return int(number.group()) if number else None


def servings(text):
    """'6-8' -> 6, '10 bowls' -> 10, '' -> None."""
    number = re.search(r"\d+", clean(text))
    return int(number.group()) if number else None


def side_dishes(text):
    side = not_applicable(text)
    if not side:
        return []
    side = {"Toast bread": "Toast"}.get(side, side)
    return [side[0].upper() + side[1:]]


def photo_for(photos, kind, name):
    entry = photos.get(f"{kind}:{name}")
    return entry["output"] if entry else None


def convert_meal(record, photos):
    name = clean(record["name"])
    return {
        "name": NAMES.get(name, name),
        "type": meal_type(record.get("type")),
        "description": clean(record.get("description")),
        "drink": not_applicable(record.get("drink")),
        "sideDishes": side_dishes(record.get("sideDish")),
        "image": photo_for(photos, "meal", name),
        "nutritionFactImages": [],
        "isFavourite": bool(record.get("isMealLiked")),
    }


def convert_recipe(record, photos):
    name = clean(record["name"])
    preparation = record.get("preparationTime", "")
    recipe = {
        "name": NAMES.get(name, name),
        "type": meal_type(record.get("type")),
        "description": clean(record.get("description")),
        "ingredients": clean_list(record.get("ingredients")),
        "instructions": clean_list(record.get("instructions")),
        "preparationMinutes": minutes(preparation),
        "cookingMinutes": minutes(record.get("cookingTime")),
        "servings": servings(record.get("servingSize")),
        "image": photo_for(photos, "recipe", name),
        "isSideDish": bool(record.get("isSideDish")),
        "isFavourite": bool(record.get("isRecipeLiked")),
    }
    # Keep wording a number cannot hold, such as an overnight marinade.
    if re.search(r"[a-z]{4,}", clean(preparation).lower().replace("mins", "")):
        note = f"Preparation: {clean(preparation)}."
        recipe["description"] = f"{recipe['description']} {note}".strip()
    return recipe


def planned_meals(schedules, meal_ids):
    """Firestore kept the plan under mealschedules/<year>/<month>/<doc>."""
    plan = {}
    for year, year_doc in schedules.items():
        for month, entries in (year_doc.get("subcollections") or {}).items():
            for doc_id, doc in entries.items():
                data = doc.get("data") or {}
                day = data.get("selectedDayCalendarNum")
                if data.get("id") not in meal_ids or not day or month not in MONTHS:
                    continue
                plan[f"firestore-{year}-{doc_id}"] = {
                    "mealId": data["id"],
                    "day": f"{int(year):04d}-{MONTHS[month]:02d}-{int(day):02d}",
                    "slot": meal_type(data.get("type")),
                }
    return plan


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("export", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()

    export = json.loads(args.export.read_text(encoding="utf-8"))
    photos = json.loads(PHOTOS.read_text(encoding="utf-8")) if PHOTOS.exists() else {}

    meals = {doc_id: convert_meal(doc["data"], photos) for doc_id, doc in export.get("meals", {}).items()}
    recipes = {doc_id: convert_recipe(doc["data"], photos) for doc_id, doc in export.get("recipes", {}).items()}
    by_name = lambda records: dict(sorted(records.items(), key=lambda kv: kv[1]["name"].lower()))
    meals, recipes = by_name(meals), by_name(recipes)

    now = datetime.now()
    output = args.output or Path(f"yummealprep-backup-{now:%Y%m%d-%H%M%S}.backup")
    backup = {
        "format": "yummealprep-backup",
        "version": 1,
        "exportedAt": now.astimezone(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "meals": meals,
        "recipes": recipes,
        "mealPlan": planned_meals(export.get("mealschedules", {}), set(meals)),
        "images": {},
    }
    write(output, backup)
    missing = sum(1 for item in {**meals, **recipes}.values() if not item["image"])
    print(f"{output}: {len(meals)} meals, {len(recipes)} recipes, "
          f"{len(backup['mealPlan'])} planned meals, {missing} without a photo")


def write(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
