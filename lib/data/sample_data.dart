import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sembast/sembast.dart';

import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/backup_service.dart';
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
      if (await settings.seedVersion(transaction) >= version) return;
      for (final MapEntry(key: id, value: meal) in contents.meals.entries) {
        await _addIfMissing(
          transaction,
          AppDatabase.meals,
          id,
          Meal.fromMap(id, meal).toMap(),
        );
      }
      for (final MapEntry(key: id, value: recipe) in contents.recipes.entries) {
        await _addIfMissing(
          transaction,
          AppDatabase.recipes,
          id,
          Recipe.fromMap(id, recipe).toMap(),
        );
      }
      await settings.setSeedVersion(version, transaction);
    });
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
