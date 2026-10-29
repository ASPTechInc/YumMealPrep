import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/backup_service.dart';
import 'package:yummealprep/data/sample_data.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/utils/constants.dart';

void main() {
  late AppServices services;
  late SampleData sampleData;
  final json = File(Constants.seedData).readAsStringSync();

  setUp(() async {
    services = await AppServices.inMemory();
    sampleData = SampleData(services.database, services.settings);
  });
  tearDown(() => services.close());

  test('the bundled sample data is a valid backup', () {
    final contents = BackupService.parse(utf8.encode(json));
    expect(contents.meals, isNotEmpty);
    expect(contents.recipes, isNotEmpty);
    expect(contents.sampleDataVersion, greaterThanOrEqualTo(1));

    for (final MapEntry(key: id, value: item) in {
      ...contents.meals,
      ...contents.recipes,
    }.entries) {
      expect(item['name'], isA<String>(), reason: id);
      expect(
        MealType.values.map((type) => type.name),
        contains(item['type']),
        reason: '$id has an unknown type',
      );
      expect(item.containsKey('searchKeywords'), isFalse, reason: id);
      final image = item['image'];
      expect(image, isA<String>(), reason: '$id has no photo');
      expect(
        File(image! as String).existsSync(),
        isTrue,
        reason: '$id refers to a missing photo: $image',
      );
    }
  });

  test('every bundled photo has a credit', () {
    final sources =
        jsonDecode(File('scripts/photo-sources.json').readAsStringSync())
            as Map<String, Object?>;
    final credited = {
      for (final entry in sources.values.cast<Map<String, Object?>>())
        entry['output'],
    };
    final photos = Directory('assets/images')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.webp'));
    expect(photos, isNotEmpty);
    for (final photo in photos) {
      expect(credited, contains(photo), reason: '$photo has no credit');
    }
    for (final type in MealType.values) {
      expect(File(type.image).existsSync(), isTrue, reason: type.image);
    }
  });

  test('adds the sample meals and recipes once', () async {
    await sampleData.addFromJson(json);
    final meals = await services.meals.getAll();
    final recipes = await services.recipes.getAll();
    expect(meals, isNotEmpty);
    expect(recipes, isNotEmpty);

    await sampleData.addFromJson(json);
    expect(await services.meals.getAll(), hasLength(meals.length));
  });

  test('does not bring back sample items the user deleted', () async {
    await sampleData.addFromJson(json);
    final meal = (await services.meals.getAll()).first;
    await services.meals.delete(meal.id);

    await sampleData.addFromJson(json);
    expect(await services.meals.get(meal.id), isNull);
  });

  test('is a small sample with at most two meals and two recipes', () {
    final contents = BackupService.parse(utf8.encode(json));
    expect(contents.meals.length, inInclusiveRange(1, 2));
    expect(contents.recipes.length, inInclusiveRange(1, 2));
  });

  test('keeps recipe steps in their written order', () async {
    await sampleData.addFromJson(json);
    final lasagne = (await services.recipes.getAll()).firstWhere(
      (recipe) => recipe.name == 'Lasagne',
    );
    expect(lasagne.instructions.first, startsWith('Heat oil'));
    expect(lasagne.instructions.length, greaterThan(5));
  });
}
