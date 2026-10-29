import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/image_references.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/planned_meal.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/services/image_store.dart';

/// Thrown when a file is not a YumMealPrep backup or cannot be read.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// How much a restore added or updated.
@immutable
class BackupSummary {
  const BackupSummary({
    required this.meals,
    required this.recipes,
    required this.plannedMeals,
  });

  final int meals;
  final int recipes;
  final int plannedMeals;

  @override
  String toString() =>
      '$meals meals, $recipes recipes and $plannedMeals planned meals';
}

/// Exports everything to a single JSON file and restores it again.
///
/// Pictures saved by the app are embedded in the file, so a backup can be
/// moved to another device on its own. Backups are plain, documented JSON
/// (see `docs/backup-format.md`) so your data is never locked in.
class BackupService {
  BackupService(this.database, this.images);

  static const String format = 'yummealprep-backup';
  static const int version = 1;

  final AppDatabase database;
  final ImageStore images;

  Future<Uint8List> export({DateTime? now}) async {
    final db = database.db;
    final meals = await AppDatabase.meals.find(db);
    final recipes = await AppDatabase.recipes.find(db);
    final plan = await AppDatabase.mealPlan.find(db);

    final embedded = <String, String>{};
    Future<void> embed(Iterable<String> sources) async {
      for (final source in sources) {
        if (!images.owns(source) || embedded.containsKey(source)) continue;
        final bytes = await images.readBytes(source);
        if (bytes != null) embedded[source] = base64Encode(bytes);
      }
    }

    for (final record in meals) {
      await embed(Meal.fromMap(record.key, record.value).imageSources);
    }
    for (final record in recipes) {
      await embed(Recipe.fromMap(record.key, record.value).imageSources);
    }

    final backup = {
      'format': format,
      'version': version,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'meals': {for (final record in meals) record.key: record.value},
      'recipes': {for (final record in recipes) record.key: record.value},
      'mealPlan': {for (final record in plan) record.key: record.value},
      'images': embedded,
    };
    return utf8.encode(const JsonEncoder.withIndent('  ').convert(backup));
  }

  /// Reads a backup without changing anything. Accepts this app's format
  /// (docs/backup-format.md) and sembast's own export format, as written by
  /// `exportDatabase` in `package:sembast/utils/sembast_import_export.dart`.
  static BackupContents parse(Uint8List bytes) {
    final Map<String, Object?> json;
    try {
      json = (jsonDecode(utf8.decode(bytes)) as Map).cast<String, Object?>();
    } on Object {
      throw const BackupFormatException('This file is not a valid backup.');
    }
    if (json.containsKey('sembast_export')) return _parseSembastExport(json);
    if (json['format'] != format) {
      throw const BackupFormatException(
        'This file is not a YumMealPrep backup.',
      );
    }
    if (_readInt(json['version']) > version) {
      throw const BackupFormatException(
        'This backup was made by a newer version of YumMealPrep. '
        'Update the app and try again.',
      );
    }
    return BackupContents(
      meals: _records(json['meals']),
      recipes: _records(json['recipes']),
      mealPlan: _records(json['mealPlan']),
      images: {
        for (final entry in _map(json['images']).entries)
          if (entry.value is String) entry.key: entry.value! as String,
      },
      sampleDataVersion: _readInt(json['sampleDataVersion']),
    );
  }

  /// sembast's format lists each store as parallel `keys` and `values`.
  static BackupContents _parseSembastExport(Map<String, Object?> json) {
    final stores = <String, Map<String, Map<String, Object?>>>{};
    for (final store
        in (json['stores'] as List? ?? const []).whereType<Map>()) {
      final keys = store['keys'] as List? ?? const [];
      final values = store['values'] as List? ?? const [];
      stores[store['name'].toString()] = {
        for (var i = 0; i < keys.length && i < values.length; i++)
          if (values[i] is Map) keys[i].toString(): _map(values[i]),
      };
    }
    return BackupContents(
      meals: stores[AppDatabase.meals.name] ?? const {},
      recipes: stores[AppDatabase.recipes.name] ?? const {},
      mealPlan: stores[AppDatabase.mealPlan.name] ?? const {},
      images: const {},
    );
  }

  /// Restores a backup made by [export], an edited copy of one, or a sembast
  /// export.
  ///
  /// By default items are added, and items with the same id are replaced;
  /// nothing else is removed. With [replaceAll], every meal, recipe and
  /// planned meal is removed first, so the app ends up matching the file
  /// exactly. This is how edits such as deleting an item in the file take
  /// effect.
  Future<BackupSummary> restore(
    Uint8List bytes, {
    bool replaceAll = false,
  }) async {
    final contents = parse(bytes);

    // Save the embedded pictures first, then point the items at the copies.
    final renamed = <String, String>{};
    for (final entry in contents.images.entries) {
      try {
        renamed[entry.key] = await images.save(
          base64Decode(entry.value),
          extension: entry.key.split('.').last,
        );
      } on FormatException {
        // Skip a damaged picture rather than failing the whole restore.
      }
    }
    // Pictures referred to but not embedded (as in a sembast export) are
    // kept if this device already has them. Names are content hashes, so
    // an existing file is the right picture.
    final available = <String>{};
    for (final record in [
      ...contents.meals.values.map((map) => Meal.fromMap('', map)),
      ...contents.recipes.values.map((map) => Recipe.fromMap('', map)),
    ]) {
      for (final source in record.imageSources) {
        if (images.owns(source) &&
            !renamed.containsKey(source) &&
            await images.readBytes(source) != null) {
          available.add(source);
        }
      }
    }
    String? rename(String? source) => source == null
        ? null
        : renamed[source] ?? _keepIfUsable(source, available);

    final meals = contents.meals.entries.map((entry) {
      final meal = Meal.fromMap(entry.key, entry.value);
      return meal.copyWith(
        image: () => rename(meal.image),
        nutritionFactImages: meal.nutritionFactImages
            .map(rename)
            .whereType<String>()
            .toList(),
      );
    }).toList();
    final recipes = contents.recipes.entries.map((entry) {
      final recipe = Recipe.fromMap(entry.key, entry.value);
      return recipe.copyWith(image: () => rename(recipe.image));
    }).toList();
    final mealIds = {for (final meal in meals) meal.id};
    final plan = contents.mealPlan.entries
        .map((entry) => PlannedMeal.fromMap(entry.key, entry.value))
        .toList();

    final db = database.db;
    final previousImages = await imagesInUse(db);

    var plannedMeals = 0;
    await db.transaction((transaction) async {
      if (replaceAll) {
        await AppDatabase.meals.delete(transaction);
        await AppDatabase.recipes.delete(transaction);
        await AppDatabase.mealPlan.delete(transaction);
      }
      for (final meal in meals) {
        await AppDatabase.meals.record(meal.id).put(transaction, meal.toMap());
      }
      for (final recipe in recipes) {
        await AppDatabase.recipes
            .record(recipe.id)
            .put(transaction, recipe.toMap());
      }
      for (final entry in plan) {
        final mealExists =
            mealIds.contains(entry.mealId) ||
            await AppDatabase.meals.record(entry.mealId).exists(transaction);
        if (!mealExists) continue;
        await AppDatabase.mealPlan
            .record(entry.id)
            .put(transaction, entry.toMap());
        plannedMeals++;
      }
    });

    // Pictures that only replaced or deleted items used are not needed any
    // more. Pictures are named by their contents, so importing a file
    // again reuses the files already saved rather than adding copies.
    await deleteUnusedImages(db, images, previousImages);

    return BackupSummary(
      meals: meals.length,
      recipes: recipes.length,
      plannedMeals: plannedMeals,
    );
  }

  /// Keeps bundled assets, inline pictures and pictures already on this
  /// device; drops references to files that are missing.
  String? _keepIfUsable(String source, Set<String> available) =>
      ImageStore.isAsset(source) ||
          source.startsWith('data:') ||
          available.contains(source)
      ? source
      : null;

  static int _readInt(Object? value) => value is num ? value.toInt() : 0;

  static Map<String, Map<String, Object?>> _records(Object? value) => {
    for (final entry in _map(value).entries)
      if (entry.value is Map) entry.key: _map(entry.value),
  };

  static Map<String, Object?> _map(Object? value) =>
      value is Map ? value.cast<String, Object?>() : const {};
}

/// The records in a backup file, keyed by id, before they are restored.
@immutable
class BackupContents {
  const BackupContents({
    required this.meals,
    required this.recipes,
    required this.mealPlan,
    required this.images,
    this.sampleDataVersion = 0,
  });

  final Map<String, Map<String, Object?>> meals;
  final Map<String, Map<String, Object?>> recipes;
  final Map<String, Map<String, Object?>> mealPlan;

  /// Embedded pictures: image source to base64-encoded bytes.
  final Map<String, String> images;

  /// Set in the bundled sample data, so new samples can be added later.
  final int sampleDataVersion;
}

/// The extension of exported files. They contain plain JSON.
const String backupExtension = 'backup';

/// A file name such as `yummealprep-backup-20261028-213707.backup`, using
/// the local date and time of [date].
String backupFileName(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  final day = '${date.year}${two(date.month)}${two(date.day)}';
  final time = '${two(date.hour)}${two(date.minute)}${two(date.second)}';
  return '${BackupService.format}-$day-$time.$backupExtension';
}
