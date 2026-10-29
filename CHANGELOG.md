# v1.0.0

First free and open-source (FOSS) release of YumMealPrep, a meal planner and digital recipe book
built with Flutter. The app no longer uses Firebase: everything is stored on your device and works
offline.

### Features

- Meal planner calendar (month, two-week or week view) with coloured markers for planned meals.
  A day can hold any number of meals, and the same meal can be planned on as many days as you like.
- Plan a meal from the planner (choosing the slot and meal) or from a meal's page (choosing the
  date). Swipe a planned meal away to remove it, with undo.
- Meals with a picture, drink, side dishes and photos of nutrition labels. Pictures are optional:
  items without one show a "no picture" placeholder, as do pictures that cannot be loaded.
- Pictures you add are resized to at most 1600 pixels, saved as JPEG without their metadata (such
  as location), and stored once even if several items use them.
- Recipes with ingredients you can tick off while cooking, numbered steps, and preparation time,
  cooking time and servings.
- Browse meals and recipes by category, with a count for each.
- Search meals and recipes by name, description, ingredients, drink and side dishes, ignoring
  accents and treating "&" and "and" alike. The stored keyword lists are gone.
- Favourites for meals and recipes. Swipe one away to unfavourite it, with undo.
- Share or print any meal or recipe as a PDF, generated on the device with bundled fonts.
- Export everything, pictures included, to one editable `.backup` file (plain JSON) named like
  `yummealprep-backup-20261028-213707.backup`. Import adds to your data or replaces it, so you
  can edit an export on a computer and load it back. sembast's own export format is accepted too.
- Two sample meals and two sample recipes show how the app works on first launch. Add your own
  with the Add meal and Add recipe buttons (only a name is required), or import them. Leaving a
  form with unsaved changes asks first.
- `scripts/pack-backup.py` turns a hand-written file, with pictures as file paths or web
  addresses, into a `.backup` with the pictures embedded.
- Freely licensed food photos from Wikimedia Commons (credits in the side menu).
- Light, dark and system themes, with your choice saved on the device.
- Side menu with import and export, privacy policy, what's new, source code, issue tracker and About
  (version and open-source licences).
- No accounts, analytics or adverts, and no internet permission on Android. Released under the
  MIT licence.

### Changes from the Firebase version

- Cloud Firestore, Firebase Storage and Firebase Authentication have been replaced by a local
  [sembast](https://pub.dev/packages/sembast) database and pictures stored in the app's own
  storage.
- Removed the developer-only "Upload Items" screen and the `.env` configuration, which was being
  bundled into the app.
- Fonts are no longer downloaded from Google Fonts.
- Replaced the stock photos of unknown origin with credited, freely licensed WebP photos.
- Nutrition label photos from Firebase Storage could not be carried over.
- Fixed: a day could only hold one planned meal.
- Fixed: a meal could only ever be planned once.
- Fixed: swiping a meal out of the plan left it planned and removed it from favourites instead.
- Fixed: adding and editing meals and recipes did not save.
- Fixed: deleting a recipe did nothing, because it looked for the recipe among the meals.
- Fixed: shared recipe PDFs listed the method steps in alphabetical order and cut off long
  recipes.
- Fixed: favourite buttons did not update until the screen was reopened.
- Removed 37 dependencies, many of them unmaintained, in favour of Flutter's built-in Material 3
  widgets. The app now depends on 13 packages, all free software.
- Unit, widget and on-device integration tests, which also take the store screenshots.
