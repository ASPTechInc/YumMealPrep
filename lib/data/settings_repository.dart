import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';

import 'package:yummealprep/data/app_database.dart';

/// App preferences, kept in the same local database as everything else.
class SettingsRepository {
  SettingsRepository._(this.database, ThemeMode themeMode)
    : themeMode = ValueNotifier(themeMode);

  static const String _themeModeKey = 'themeMode';
  static const String _seedVersionKey = 'seedVersion';

  final AppDatabase database;

  /// The chosen theme. The app rebuilds when this changes.
  final ValueNotifier<ThemeMode> themeMode;

  Database get _db => database.db;

  static Future<SettingsRepository> load(AppDatabase database) async {
    final stored = await AppDatabase.settings
        .record(_themeModeKey)
        .get(database.db);
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
    return SettingsRepository._(database, themeMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await AppDatabase.settings.record(_themeModeKey).put(_db, mode.name);
  }

  /// The version of the sample data last added, or 0 if it never was.
  Future<int> seedVersion([DatabaseClient? client]) async {
    final value = await AppDatabase.settings
        .record(_seedVersionKey)
        .get(client ?? _db);
    return value is int ? value : 0;
  }

  Future<void> setSeedVersion(int version, [DatabaseClient? client]) =>
      AppDatabase.settings.record(_seedVersionKey).put(client ?? _db, version);

  void dispose() => themeMode.dispose();
}
