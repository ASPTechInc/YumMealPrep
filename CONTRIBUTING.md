# Contributing to YumMealPrep

Thanks for your interest in contributing to **YumMealPrep**!
YumMealPrep is a free and open-source (FOSS) meal planner and recipe book, and contributions of all
sizes are welcome, from fixing a typo in a sample recipe to building a shopping list.

---

## How to Contribute

1. **Fork the repository** to your own GitHub account.
2. **Clone your fork** to your local machine.
3. **Create a new branch** for your work:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes**, following the code style below.
5. **Run the tests** and check they still pass.
6. **Commit your changes** with messages that say what changed and why.
7. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
8. **Create a pull request** from your fork's branch to the `main` branch of the original repository.

---

## Project setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel; CI
   uses the version in [.github/workflows/ci.yml](.github/workflows/ci.yml)).
2. Fetch the dependencies and run the app:
   ```bash
   flutter pub get
   flutter run              # on a connected phone or emulator
   flutter run -d linux     # or as a desktop app
   ```

No accounts, API keys or `.env` file are needed. The app creates its database on first run and
fills it with the sample meals and recipes.

---

## Technical Stack

YumMealPrep is a cross-platform Flutter app that works entirely offline:

- **Language**: [Dart](https://dart.dev/)
- **Framework**: [Flutter SDK](https://flutter.dev/), Material 3 widgets
- **Storage**: [sembast](https://pub.dev/packages/sembast), a pure-Dart document database (IndexedDB
  through [sembast_web](https://pub.dev/packages/sembast_web) on the web)
- **State**: live database streams and `setState`. Services are shared through `AppScope` in
  `lib/app_services.dart`
- **Calendar**: [table_calendar](https://pub.dev/packages/table_calendar)
- **PDFs**: [pdf](https://pub.dev/packages/pdf) and [printing](https://pub.dev/packages/printing),
  with the bundled Noto Sans font
- **Pictures and backups**: [file_picker](https://pub.dev/packages/file_picker)

### Project layout

```text
lib/
  main.dart              Opens the database, adds sample data, starts the app
  app.dart               MaterialApp and themes
  app_services.dart      AppServices (repositories, images, backup) and AppScope
  models/                Meal, Recipe, PlannedMeal and MealType (plain Dart, immutable)
  data/                  Database, repositories, sample data and backup (plain Dart, unit tested)
  services/              Picture storage and PDF generation
  screens/               One folder per screen
  widgets/               Widgets shared between screens
  utils/                 Search, dates, ids and other helpers
assets/data/seed.json    The sample meals and recipes
docs/backup-format.md    The backup file format
```

Keep logic in plain Dart classes and functions (such as `filterItems`, `matchesQuery` and the
repositories) where possible, so it can be tested without building widgets.

---

## Code Style

- **Formatting**: Run `dart format lib test` before committing changes.
- **Imports**: Use package imports (`package:yummealprep/...`). Run `dart run import_sorter:main`
  to sort them.
- **Linting**: `flutter analyze` should report no issues. The lint rules are in
  [analysis_options.yaml](analysis_options.yaml).
- **Spelling**: User-facing text and documentation use British English (e.g. "colour",
  "favourite", "flavourful").
- **Scope**: Keep each pull request to one feature or bug fix.
- **Privacy**: Do not add network access, analytics, adverts or non-free dependencies (anything
  from Firebase or Google Play services, for example). `./scripts/foss_audit.sh` checks this, and
  CI runs it on every pull request so the app can stay on F-Droid.

The [pre-commit](https://pre-commit.com) hooks in [.pre-commit-config.yaml](.pre-commit-config.yaml)
run the formatter, import sorter, analyser and FOSS audit for you:

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install pre-commit
pre-commit install
```

---

## Updating the sample meals and recipes

The sample data in [assets/data/seed.json](assets/data/seed.json) is added the first time the app
runs, so new users can see how the app works. Keep it small: at most two meals and two recipes.
People add their own with the **Add meal** and **Add recipe** buttons, or with **Import data**.
The file is an ordinary backup in the [documented format](docs/backup-format.md). Each meal
looks like this:

```json
"EydGfAfwAR7vHM3yXmJ4": {
  "name": "Fish & Chips",
  "type": "lunch",
  "description": "Fish and chips is a hot dish consisting of fried fish in batter...",
  "drink": "Juice",
  "sideDishes": [],
  "image": "assets/images/meals/fish-and-chips.webp",
  "nutritionFactImages": [],
  "isFavourite": false
}
```

Recipes have `ingredients`, `instructions` (in order), `preparationMinutes`, `cookingMinutes`,
`servings` and `isSideDish` instead of the drink and side dishes.

- `type` is one of `appetisers`, `breakfast`, `lunch`, `dinner`, `dessert` or `smoothies`.
- Ids must be unique and should not change once released.
- Search works on the text itself, so there is no keyword list to maintain.
- The sample data is added once per `sampleDataVersion`. To give existing users new items,
  increase it; items people have deleted are not added back.

`test/data/sample_data_test.dart` checks the file, including that every photo exists and is
credited.

### Photos

The photos for the full original catalogue (see `scripts/convert-firestore-export.py`) are
bundled, so an imported `.backup` from that catalogue shows its pictures. Every food photo is freely licensed (CC0, public domain, CC BY or CC BY-SA) and listed in
[scripts/photo-sources.json](scripts/photo-sources.json) with its source, author and licence. To add
or change one:

1. Find a photo on [Wikimedia Commons](https://commons.wikimedia.org/) under one of those licences
   (not "NC" or "ND"), and add or edit its entry in the manifest.
2. Run `scripts/fetch-photos.py download` to download it, crop it to 4:3 and convert it to WebP
   with `scripts/process-images.sh`.
3. Run `scripts/fetch-photos.py credits` to update `assets/images/CREDITS.md` (shown in the app
   under **Photo credits**) and `assets/images/REUSE.toml`.
4. Check with `pipx run reuse lint`. If the photo uses a new licence, add its text with
   `pipx run reuse download <SPDX id>`.

---

## Testing

Please add or update tests when you change the app. There are three kinds:

- **Unit tests** (`test/data`, `test/models`, `test/services`, `test/utils`) check the logic, such
  as the repositories, search, backups, pictures and PDFs.
- **Widget tests** (`test/widget`) drive the screens with taps and typing: adding, planning,
  favouriting, editing and deleting. Both kinds use an in-memory database
  (`AppServices.inMemory()`), so they need no device.
- **Integration tests** (`integration_test/`) run the real app on a phone or emulator, with its
  real database, file storage and picture processing. On Android they run as instrumentation
  tests, and CI runs them on an emulator.

```bash
flutter test                                       # unit and widget tests
flutter test --coverage                            # with coverage in coverage/lcov.info
flutter test integration_test/app_test.dart -d <device>
```

### Store screenshots

`integration_test/screenshots_test.dart` takes the screenshots in
`fastlane/metadata/android/en-GB/images/phoneScreenshots/` from a set of everyday dishes (not
anyone's personal data). Run it on a phone-sized emulator, light theme, after UI changes:

```bash
flutter drive --driver=test_driver/integration_test.dart \
    --target=integration_test/screenshots_test.dart -d <device>
```

The driver reduces each screenshot to 256 colours, so they stay under the 600 KB limit for added
files.

### Flutter version

CI, release builds and F-Droid all use the exact Flutter release pinned in
`.github/workflows/*.yml` and `metadata/com.asptechinc.yummealprep.yml`. To move to a newer
stable release, run the checks above with it (including a release build), then update every pin
in the same pull request.

---

## Reporting Issues

If you find a bug or have a feature request, please
[open an issue](https://github.com/ASPTechInc/YumMealPrep/issues). The
[roadmap](docs/roadmap.md) lists ideas that are already planned.

Please report security vulnerabilities privately, as described in [SECURITY.md](SECURITY.md).

By taking part in this project you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
