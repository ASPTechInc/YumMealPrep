import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/backup_service.dart';
import 'package:yummealprep/data/settings_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/services/image_store.dart';
import 'package:yummealprep/services/image_store_io.dart';

Future<AppServices> servicesWithFiles(Directory directory) async {
  final database = await AppDatabase.inMemory();
  return AppServices(
    database: database,
    images: FileImageStore(directory),
    settings: await SettingsRepository.load(database),
  );
}

void main() {
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
          image: 'assets/images/recipes/vegetable-rice.webp',
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
        'assets/images/recipes/vegetable-rice.webp',
      );

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

  test('skips planned meals whose meal is not available', () async {
    final services = await AppServices.inMemory();
    final backup = utf8.encode(
      jsonEncode({
        'format': 'yummealprep-backup',
        'version': 1,
        'meals': <String, Object?>{},
        'recipes': <String, Object?>{},
        'mealPlan': {
          'p1': {'mealId': 'missing', 'day': '2026-11-02', 'slot': 'lunch'},
        },
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
      final meals = backup['meals']! as Map<String, Object?>;
      (meals['kept']! as Map<String, Object?>)['name'] = 'Pelau with Coleslaw';
      meals.remove('gone');
      (backup['mealPlan']! as Map<String, Object?>).clear();
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

  // A personal backup kept beside the sample data. It is ignored by git, so
  // the test only runs where the file exists.
  final personal = File(
    'assets/data/yummealprep-backup-20261028-213707.backup',
  );
  test(
    'imports the personal .backup file as it is',
    () async {
      final services = await AppServices.inMemory();
      final summary = await services.backup.restore(
        personal.readAsBytesSync(),
        replaceAll: true,
      );
      expect(summary.meals, greaterThan(2));
      for (final meal in await services.meals.getAll()) {
        final image = meal.image;
        if (image != null) {
          expect(File(image).existsSync(), isTrue, reason: image);
        }
      }
      await services.close();
    },
    skip: personal.existsSync() ? false : 'No personal backup on this machine',
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
          'meals': {
            'm': {
              'name': 'Soup',
              'type': 'lunch',
              'image': 'assets/images/meals/pelau.webp',
            },
          },
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
