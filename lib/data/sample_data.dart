// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/services.dart';

// Package imports:
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/backup_service.dart';
import 'package:yummealprep/data/choice_list_repository.dart';
import 'package:yummealprep/data/settings_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/utils/constants.dart';

/// Adds the bundled sample meals and recipes the first time the app runs,
/// so a new cook book is not empty.
///
/// The sample data is an ordinary backup file (see docs/backup-format.md)
/// with a `sampleDataVersion`. It is added once per version: anything you
/// delete stays deleted, and your own changes are never overwritten.
///
/// It also holds the side dish and drink lists the meal form starts with.
class SampleData {
  SampleData(this.database, this.settings);

  final AppDatabase database;
  final SettingsRepository settings;

  Future<void> addIfNeeded({AssetBundle? bundle}) async {
    final json = await (bundle ?? rootBundle).loadString(Constants.seedData);
    await addFromJson(json);
  }

  Future<void> addFromJson(String json) async {
    final contents = BackupService.parse(utf8.encode(json));
    final version = contents.sampleDataVersion < 1
        ? 1
        : contents.sampleDataVersion;
    await database.db.transaction((transaction) async {
      if (await settings.seedVersion(transaction) < version) {
        final meals = [
          for (final MapEntry(key: id, value: map) in contents.meals.entries)
            Meal.fromMap(id, map),
        ];
        final recipes = [
          for (final MapEntry(key: id, value: map) in contents.recipes.entries)
            Recipe.fromMap(id, map),
        ];
        for (final meal in meals) {
          await _addIfMissing(
            transaction,
            AppDatabase.meals,
            meal.id,
            meal.toMap(),
          );
        }
        for (final recipe in recipes) {
          await _addIfMissing(
            transaction,
            AppDatabase.recipes,
            recipe.id,
            recipe.toMap(),
          );
        }
        final used = ChoiceList.usedBy(meals, recipes);
        for (final list in ChoiceList.values) {
          await ChoiceListRepository(
            database,
            list,
          ).add([...?contents.choices[list], ...?used[list]], transaction);
        }
        await settings.setSeedVersion(version, transaction);
      }
      await _startMissingChoices(transaction, contents.choices);
    });
  }

  /// Copies of the app from before the side dish and drink lists existed
  /// already have their sample data, so start their lists here from the
  /// sample lists and every name their meals and recipes already use.
  Future<void> _startMissingChoices(
    Transaction transaction,
    Map<ChoiceList, List<String>> sample,
  ) async {
    final missing = [
      for (final list in ChoiceList.values)
        if (!await ChoiceListRepository(database, list).exists(transaction))
          list,
    ];
    if (missing.isEmpty) return;
    final used = ChoiceList.usedBy(
      [
        for (final record in await AppDatabase.meals.find(transaction))
          Meal.fromMap(record.key, record.value),
      ],
      [
        for (final record in await AppDatabase.recipes.find(transaction))
          Recipe.fromMap(record.key, record.value),
      ],
    );
    for (final list in missing) {
      await ChoiceListRepository(
        database,
        list,
      ).replace([...?sample[list], ...?used[list]], transaction);
    }
  }

  static Future<void> _addIfMissing(
    Transaction transaction,
    RecordStore store,
    String id,
    Map<String, Object?> value,
  ) async {
    final record = store.record(id);
    if (!await record.exists(transaction)) {
      await record.put(transaction, value);
    }
  }
}
