# Backup file format

**Export data** in YumMealPrep's side menu saves everything to a single file named like
`yummealprep-backup-20261028-213707.backup` (the date and time of the export). A `.backup` file
is plain UTF-8 JSON, so any text editor can open it, and **Import data** loads it again. The format is documented here so your data is never
locked into the app: you can read it, edit it or convert it with any tool.

## Structure

```json
{
  "format": "yummealprep-backup",
  "version": 1,
  "exportedAt": "2026-10-28T19:04:11.000Z",
  "meals": {
    "<id>": { "name": "Pelau", "type": "lunch", "...": "..." }
  },
  "recipes": {
    "<id>": { "name": "White Rice", "type": "lunch", "...": "..." }
  },
  "mealPlan": {
    "<id>": { "mealId": "<meal id>", "day": "2026-11-02", "slot": "dinner" }
  },
  "images": {
    "local:images/<file>.jpg": "<base64-encoded picture>"
  }
}
```

| Field        | Meaning                                                                       |
| ------------ | ----------------------------------------------------------------------------- |
| `format`     | Always `yummealprep-backup`.                                                  |
| `version`    | The format version. The app refuses backups from a newer version than itself. |
| `sampleDataVersion` | Only in the bundled sample data (`assets/data/seed.json`). |
| `exportedAt` | When the backup was made, in UTC.                                             |
| `meals`      | Meals, keyed by id.                                                           |
| `recipes`    | Recipes, keyed by id.                                                         |
| `mealPlan`   | Planned meals, keyed by id.                                                   |
| `images`     | Pictures added in the app, keyed by the source the items use.                 |

### Meal

| Field                 | Type             | Notes                                                |
| --------------------- | ---------------- | ---------------------------------------------------- |
| `name`                | string           |                                                      |
| `type`                | string           | `appetisers`, `breakfast`, `lunch`, `dinner`, `dessert` or `smoothies` |
| `description`         | string           |                                                      |
| `drink`               | string           |                                                      |
| `sideDishes`          | list of strings  |                                                      |
| `image`               | string or null   | An image source (see below).                         |
| `nutritionFactImages` | list of strings  | Image sources of nutrition label photos.             |
| `isFavourite`         | boolean          |                                                      |

### Recipe

| Field                | Type            | Notes                          |
| -------------------- | --------------- | ------------------------------ |
| `name`               | string          |                                |
| `type`               | string          | As for meals.                  |
| `description`        | string          |                                |
| `ingredients`        | list of strings |                                |
| `instructions`       | list of strings | In the order they are carried out. |
| `preparationMinutes` | number or null  |                                |
| `cookingMinutes`     | number or null  |                                |
| `servings`           | number or null  |                                |
| `image`              | string or null  | An image source.               |
| `isSideDish`         | boolean         |                                |
| `isFavourite`        | boolean         |                                |

### Planned meal

| Field    | Type   | Notes                                   |
| -------- | ------ | --------------------------------------- |
| `mealId` | string | The id of a meal.                       |
| `day`    | string | The date, as `yyyy-MM-dd`.              |
| `slot`   | string | Which part of the day, as for `type`.   |

### Image sources

- `assets/...`: a picture bundled with the app, such as the sample meals' pictures. These are not
  embedded, because every copy of the app has them.
- `local:images/<hash>.jpg`: a picture you added. Its bytes are embedded in `images`.
- `data:image/...;base64,...`: a picture stored inline (used by the web version).

### Pictures you add

When you add a picture to a meal or recipe, the app saves a copy in its private storage:

- shrunk to at most 1600 pixels on its longest side and saved as JPEG, so a phone photo of several
  megabytes becomes a few hundred kilobytes;
- turned the right way up, with its metadata (camera, date and location) removed;
- named after a hash of its contents, for example `local:images/3f2a…9c1d.jpg`.

Because the name comes from the contents, the same picture is only ever stored once. Exporting
embeds exactly the pictures your items use, so a `.backup` file is always complete on its own.
Importing writes each embedded picture under the same name, so importing a file twice reuses the
files already there, and pictures that no item uses any more are deleted afterwards. A picture
shared by two items is kept until neither uses it.

## Editing your data

The backup is meant to be edited. To change many items at once, fix typos or tidy up:

1. In the app, open the side menu and choose **Export data**. Save the file somewhere you can
   reach from a computer.
2. Open it in any text editor. Each meal and recipe is one entry under `meals` or `recipes`,
   keyed by its id. Edit the fields, add entries (any unique id will do) or delete entries.
3. Copy the file back and choose **Import data**, then **Replace everything**.

Keep the JSON valid (commas between entries, double quotes around text). If the app cannot read
the file it tells you and changes nothing. Pictures you added are stored in `images` as base64
text; leave those lines as they are.

## Importing

**Import data** accepts `.backup` files (and the same JSON saved as `.json`) and offers two
modes:

- **Add to my data** adds everything in the file. Items with the same id as one already in the
  app are replaced by the copy in the file; nothing else is deleted.
- **Replace everything** deletes all meals, recipes and planned meals first, so the app ends up
  matching the file exactly. Use this after editing a backup, so deletions take effect. Pictures
  that nothing uses any more are deleted too.

Pictures are saved again on the restoring device, and planned meals whose meal is missing are
skipped. Unknown fields are ignored and missing fields fall back to empty values.

## sembast exports

The app stores its data with [sembast](https://pub.dev/packages/sembast), in three stores:
`meals`, `recipes` and `meal_plan`, each record keyed by id with the fields above. Restore also
accepts sembast's own export format, as written by `exportDatabase` in
`package:sembast/utils/sembast_import_export.dart`:

```json
{
  "sembast_export": 1,
  "version": 1,
  "stores": [
    { "name": "meals", "keys": ["<id>"], "values": [{ "name": "Pelau", "type": "lunch" }] }
  ]
}
```

The app's own format above is easier to edit, because each record sits next to its id.

## Importing the old Firebase data

`scripts/convert-firestore-export.py` converts an export of the old Cloud Firestore database into
this format: a `.backup` file with every meal, recipe and planned meal, which you can load with
**Import data**:

```bash
scripts/convert-firestore-export.py firestore-export.json   # writes yummealprep-backup-<date>-<time>.backup
```

See the comments at the top of the script for exactly what is converted.
