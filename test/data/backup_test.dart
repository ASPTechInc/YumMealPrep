// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/backup_service.dart';
import 'package:yummealprep/data/sample_data.dart';
import 'package:yummealprep/data/settings_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/services/image_store.dart';
import 'package:yummealprep/services/image_store_io.dart';
import 'package:yummealprep/utils/constants.dart';

Future<AppServices> servicesWithFiles(Directory directory) async {
  final database = await AppDatabase.inMemory();
  return AppServices(
    database: database,
    images: FileImageStore(directory),
    settings: await SettingsRepository.load(database),
  );
}

void main() {
  // Lets the backups read the bundled pictures.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory deviceA;
  late Directory deviceB;

  setUp(() {
    deviceA = Directory.systemTemp.createTempSync('yummealprep_a');
    deviceB = Directory.systemTemp.createTempSync('yummealprep_b');
  });
  tearDown(() {
    deviceA.deleteSync(recursive: true);
    deviceB.deleteSync(recursive: true);
  });

  test(
    'a backup moves meals, recipes, plan and pictures to a new device',
    () async {
      final source = await servicesWithFiles(deviceA);
      final picture = await source.images.save(
        Uint8List.fromList([1, 2, 3]),
        extension: 'png',
      );
      final meal = Meal(
        id: 'pelau',
        name: 'Pelau',
        type: MealType.lunch,
        image: picture,
        isFavourite: true,
      );
      await source.meals.save(meal);
      await source.recipes.save(
        const Recipe(
          id: 'rice',
          name: 'Rice',
          type: MealType.lunch,
          image: 'assets/images/recipes/lasagne.webp',
        ),
      );
      await source.mealPlan.add(
        mealId: 'pelau',
        date: DateTime(2026, 11, 2),
        slot: MealType.dinner,
      );
      final backup = await source.backup.export();

      final target = await servicesWithFiles(deviceB);
      final summary = await target.backup.restore(backup);

      expect(summary.meals, 1);
      expect(summary.recipes, 1);
      expect(summary.plannedMeals, 1);
      final restored = (await target.meals.get('pelau'))!;
      expect(restored.isFavourite, isTrue);
      expect(target.images.owns(restored.image!), isTrue);
      expect(await target.images.readBytes(restored.image!), [1, 2, 3]);
      // Bundled pictures are kept as they are.
      expect(
        (await target.recipes.get('rice'))!.image,
        'assets/images/recipes/lasagne.webp',
      );

      await source.close();
      await target.close();
    },
  );

  test(
    'bundled pictures reach copies of the app that do not have them',
    () async {
      const asset = 'assets/images/recipes/lasagne.webp';
      final source = await servicesWithFiles(deviceA);
      await source.recipes.save(
        const Recipe(
          id: 'rice',
          name: 'Rice',
          type: MealType.lunch,
          image: asset,
        ),
      );
      final backup = await source.backup.export();
      final bundled = await source.images.load(asset);
      expect(
        (jsonDecode(utf8.decode(backup)) as Map)['images'],
        containsPair(asset, base64Encode(bundled!)),
      );

      final target = await servicesWithFiles(deviceB);
      final olderApp = BackupService(
        target.database,
        target.images,
        bundle: _NoAssets(),
      );
      await olderApp.restore(backup);

      final restored = (await target.recipes.get('rice'))!.image!;
      expect(target.images.owns(restored), isTrue);
      expect(await target.images.readBytes(restored), bundled);

      await source.close();
      await target.close();
    },
  );

  test('rejects files that are not backups', () async {
    final services = await AppServices.inMemory();
    expect(
      () => services.backup.restore(utf8.encode('not json')),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => services.backup.restore(utf8.encode('{"format": "other"}')),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => services.backup.restore(
        utf8.encode('{"format": "yummealprep-backup", "version": 99}'),
      ),
      throwsA(isA<BackupFormatException>()),
    );
    await services.close();
  });

  group('records', () {
    Uint8List file(Object? meals) => utf8.encode(
      jsonEncode({
        'format': 'yummealprep-backup',
        'version': 1,
        'meals': meals,
      }),
    );

    test('are written as a list, each with its own id', () async {
      final services = await AppServices.inMemory();
      await services.meals.save(
        const Meal(id: 'm', name: 'Pelau', type: MealType.lunch),
      );
      final backup =
          jsonDecode(utf8.decode(await services.backup.export()))
              as Map<String, Object?>;
      final meals = backup['meals']! as List;
      expect(meals, hasLength(1));
      expect((meals.single as Map)['id'], 'm');
      expect((meals.single as Map)['name'], 'Pelau');
      await services.close();
    });

    test('are rejected when an id is used twice', () {
      expect(
        () => BackupService.parse(
          file([
            {'id': 'm', 'name': 'Pelau', 'type': 'lunch'},
            {'id': 'm', 'name': 'Soup', 'type': 'lunch'},
          ]),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('are rejected without an id', () {
      expect(
        () => BackupService.parse(
          file([
            {'name': 'Pelau', 'type': 'lunch'},
          ]),
        ),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => BackupService.parse(
          file([
            {'id': ' ', 'name': 'Pelau', 'type': 'lunch'},
          ]),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('are rejected when not a list', () {
      expect(
        () => BackupService.parse(
          file({
            'm': {'name': 'Pelau', 'type': 'lunch'},
          }),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('are read without the id among their fields', () {
      final contents = BackupService.parse(
        file([
          {'id': 'm', 'name': 'Pelau', 'type': 'lunch'},
        ]),
      );
      expect(contents.meals, {
        'm': {'name': 'Pelau', 'type': 'lunch'},
      });
    });
  });

  test('skips planned meals whose meal is not available', () async {
    final services = await AppServices.inMemory();
    final backup = utf8.encode(
      jsonEncode({
        'format': 'yummealprep-backup',
        'version': 1,
        'meals': <Object?>[],
        'recipes': <Object?>[],
        'mealPlan': [
          {
            'id': 'p1',
            'mealId': 'missing',
            'day': '2026-11-02',
            'slot': 'lunch',
          },
        ],
      }),
    );
    final summary = await services.backup.restore(backup);
    expect(summary.plannedMeals, 0);
    expect(await services.mealPlan.getAll(), isEmpty);
    await services.close();
  });

  group('FileImageStore', () {
    test('saves pictures under a relative source and deletes them', () async {
      final store = FileImageStore(deviceA);
      final source = await store.save(
        Uint8List.fromList([9]),
        extension: 'jpg',
      );
      expect(source, startsWith('local:images/'));
      expect(store.owns(source), isTrue);
      expect(await store.readBytes(source), [9]);

      await store.delete(source);
      expect(await store.readBytes(source), isNull);
    });

    test('refuses sources that point outside its folder', () async {
      final store = FileImageStore(deviceA);
      File('${deviceA.path}/secret.txt').writeAsStringSync('secret');
      expect(await store.readBytes('local:../secret.txt'), isNull);
      expect(await store.readBytes('local:images/../secret.txt'), isNull);
      expect(store.providerFor('local:/etc/passwd'), isNull);
    });

    test('does not own bundled assets', () {
      expect(FileImageStore(deviceA).owns('assets/images/food1.png'), isFalse);
      expect(ImageStore.isAsset('assets/images/food1.png'), isTrue);
    });
  });

  test('saving a meal with a new picture deletes the old one', () async {
    final services = await servicesWithFiles(deviceA);
    final first = await services.images.save(Uint8List.fromList([1]));
    final second = await services.images.save(Uint8List.fromList([2]));
    final meal = Meal(
      id: 'm',
      name: 'Soup',
      type: MealType.lunch,
      image: first,
    );
    await services.meals.save(meal);
    await services.meals.save(meal.copyWith(image: () => second));

    expect(await services.images.readBytes(first), isNull);
    expect(await services.images.readBytes(second), [2]);

    await services.meals.delete('m');
    expect(await services.images.readBytes(second), isNull);
    await services.close();
  });

  group('editing a backup', () {
    test('replaceAll makes the app match the file exactly', () async {
      final services = await AppServices.inMemory();
      const kept = Meal(id: 'kept', name: 'Pelau', type: MealType.lunch);
      const removed = Meal(id: 'gone', name: 'Pizza', type: MealType.dinner);
      await services.meals.save(kept);
      await services.meals.save(removed);
      await services.mealPlan.add(
        mealId: 'gone',
        date: DateTime(2026, 11, 2),
        slot: MealType.dinner,
      );

      // Export, then edit the file: rename one meal and delete the other.
      final backup =
          jsonDecode(utf8.decode(await services.backup.export()))
              as Map<String, Object?>;
      final meals = (backup['meals']! as List).cast<Map<String, Object?>>();
      meals.firstWhere((m) => m['id'] == 'kept')['name'] =
          'Pelau with Coleslaw';
      meals.removeWhere((m) => m['id'] == 'gone');
      (backup['mealPlan']! as List).clear();
      final edited = utf8.encode(jsonEncode(backup));

      // Merging keeps the deleted meal; replacing removes it.
      await services.backup.restore(edited);
      expect(await services.meals.get('gone'), isNotNull);

      await services.backup.restore(edited, replaceAll: true);
      expect(await services.meals.get('gone'), isNull);
      expect((await services.meals.get('kept'))!.name, 'Pelau with Coleslaw');
      expect(await services.mealPlan.getAll(), isEmpty);
      await services.close();
    });

    test('replaceAll deletes pictures nothing uses any more', () async {
      final services = await servicesWithFiles(deviceA);
      final picture = await services.images.save(Uint8List.fromList([7]));
      await services.meals.save(
        Meal(id: 'm', name: 'Soup', type: MealType.lunch, image: picture),
      );
      final empty = utf8.encode(
        jsonEncode({'format': 'yummealprep-backup', 'version': 1}),
      );
      await services.backup.restore(empty, replaceAll: true);

      expect(await services.meals.getAll(), isEmpty);
      expect(await services.images.readBytes(picture), isNull);
      await services.close();
    });

    test('imports a sembast export', () async {
      final services = await AppServices.inMemory();
      final export = utf8.encode(
        jsonEncode({
          'sembast_export': 1,
          'version': 1,
          'stores': [
            {
              'name': 'meals',
              'keys': ['m1'],
              'values': [
                {'name': 'Pelau', 'type': 'lunch'},
              ],
            },
            {
              'name': 'meal_plan',
              'keys': ['p1'],
              'values': [
                {'mealId': 'm1', 'day': '2026-11-02', 'slot': 'lunch'},
              ],
            },
          ],
        }),
      );
      final summary = await services.backup.restore(export);
      expect(summary.meals, 1);
      expect(summary.plannedMeals, 1);
      expect((await services.meals.get('m1'))!.name, 'Pelau');
      await services.close();
    });
  });

  test('exported files are named <app>-backup-yyyymmdd-hhmmss.backup', () {
    expect(
      backupFileName(DateTime(2026, 10, 28, 21, 37, 7)),
      'yummealprep-backup-20261028-213707.backup',
    );
  });

  test(
    'a backup of the sample data gives every item its picture elsewhere',
    () async {
      // Load the sample data on one device and export it, so the backup is
      // made the same way the app makes one.
      final source = await servicesWithFiles(deviceA);
      await SampleData(
        source.database,
        source.settings,
      ).addFromJson(File(Constants.seedData).readAsStringSync());
      final backup = await source.backup.export();

      // Restore it in a copy of the app without the bundled pictures, so
      // they only load if they travelled inside the backup.
      final target = await servicesWithFiles(deviceB);
      final olderApp = BackupService(
        target.database,
        target.images,
        bundle: _NoAssets(),
      );
      final summary = await olderApp.restore(backup, replaceAll: true);

      final meals = await source.meals.getAll();
      final recipes = await source.recipes.getAll();
      expect(meals, isNotEmpty);
      expect(recipes, isNotEmpty);
      expect(summary.meals, meals.length);
      expect(summary.recipes, recipes.length);
      expect(
        await target.sideDishes.getAll(),
        await source.sideDishes.getAll(),
      );
      expect(await target.drinks.getAll(), await source.drinks.getAll());

      final restored = [
        ...(await target.meals.getAll()).map((meal) => meal.imageSources),
        ...(await target.recipes.getAll()).map((recipe) => recipe.imageSources),
      ].expand((sources) => sources).toList();
      expect(restored, isNotEmpty);
      for (final image in restored) {
        expect(target.images.owns(image), isTrue, reason: image);
        expect(await target.images.readBytes(image), isNotNull, reason: image);
      }

      await source.close();
      await target.close();
    },
  );

  group('pictures stay in step with the data', () {
    int pictureFiles(Directory device) {
      final folder = Directory('${device.path}/images');
      return folder.existsSync()
          ? folder.listSync().whereType<File>().length
          : 0;
    }

    test('the same picture is stored once', () async {
      final store = FileImageStore(deviceA);
      final first = await store.save(Uint8List.fromList([1, 2, 3]));
      final second = await store.save(Uint8List.fromList([1, 2, 3]));
      expect(second, first);
      expect(pictureFiles(deviceA), 1);
    });

    test('a shared picture is kept until nothing uses it', () async {
      final services = await servicesWithFiles(deviceA);
      final picture = await services.images.save(Uint8List.fromList([5]));
      await services.meals.save(
        Meal(id: 'a', name: 'Soup', type: MealType.lunch, image: picture),
      );
      await services.recipes.save(
        Recipe(id: 'b', name: 'Soup', type: MealType.lunch, image: picture),
      );

      await services.meals.delete('a');
      expect(await services.images.readBytes(picture), [5]);

      await services.recipes.delete('b');
      expect(await services.images.readBytes(picture), isNull);
      await services.close();
    });

    test('importing the same file twice adds no extra pictures', () async {
      final source = await servicesWithFiles(deviceA);
      await source.meals.save(
        Meal(
          id: 'm',
          name: 'Soup',
          type: MealType.lunch,
          image: await source.images.save(Uint8List.fromList([8, 8])),
        ),
      );
      final backup = await source.backup.export();

      final target = await servicesWithFiles(deviceB);
      await target.backup.restore(backup);
      await target.backup.restore(backup);
      expect(pictureFiles(deviceB), 1);
      final meal = (await target.meals.get('m'))!;
      expect(await target.images.readBytes(meal.image!), [8, 8]);
      await source.close();
      await target.close();
    });

    test('a merge import deletes pictures its items replaced', () async {
      final services = await servicesWithFiles(deviceA);
      final old = await services.images.save(Uint8List.fromList([1]));
      await services.meals.save(
        Meal(id: 'm', name: 'Soup', type: MealType.lunch, image: old),
      );
      final file = utf8.encode(
        jsonEncode({
          'format': 'yummealprep-backup',
          'version': 1,
          'meals': [
            {
              'id': 'm',
              'name': 'Soup',
              'type': 'lunch',
              'image': 'assets/images/meals/pelau.webp',
            },
          ],
        }),
      );
      await services.backup.restore(file);
      expect(await services.images.readBytes(old), isNull);
      await services.close();
    });
  });

  test('a sembast export keeps pictures already on this device', () async {
    final services = await servicesWithFiles(deviceA);
    final picture = await services.images.save(Uint8List.fromList([4, 2]));
    await services.meals.save(
      Meal(id: 'm', name: 'Soup', type: MealType.lunch, image: picture),
    );
    // sembast exports carry no pictures, only references to them.
    final export = utf8.encode(
      jsonEncode({
        'sembast_export': 1,
        'version': 1,
        'stores': [
          {
            'name': 'meals',
            'keys': ['m'],
            'values': [
              {'name': 'Soup', 'type': 'lunch', 'image': picture},
            ],
          },
        ],
      }),
    );
    await services.backup.restore(export, replaceAll: true);

    expect((await services.meals.get('m'))!.image, picture);
    expect(await services.images.readBytes(picture), [4, 2]);
    await services.close();
  });

  test('inline pictures are decoded once and then reused', () async {
    final store = DataUriImageStore();
    final source = await store.save(Uint8List.fromList([1, 2, 3]));
    expect(identical(store.resolve(source), store.resolve(source)), isTrue);
  });
}

/// The assets of a copy of the app that has none of the bundled pictures.
class _NoAssets extends AssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('Unable to load asset: "$key".');

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(await loadString(key));
}
