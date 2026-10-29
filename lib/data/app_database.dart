import 'package:sembast/sembast_memory.dart';

import 'package:yummealprep/data/database_opener_io.dart'
    if (dart.library.js_interop) 'package:yummealprep/data/database_opener_web.dart'
    as platform;

typedef RecordStore = StoreRef<String, Map<String, Object?>>;

/// The app's local database. Everything is stored on the device using
/// sembast, a pure-Dart document database, so the app works offline and
/// needs no account or server.
class AppDatabase {
  AppDatabase(this.db);

  static final RecordStore meals = stringMapStoreFactory.store('meals');
  static final RecordStore recipes = stringMapStoreFactory.store('recipes');
  static final RecordStore mealPlan = stringMapStoreFactory.store('meal_plan');
  static final StoreRef<String, Object?> settings = StoreRef('settings');

  final Database db;

  /// Opens the database file in the app's private storage (IndexedDB on the
  /// web).
  static Future<AppDatabase> open() async =>
      AppDatabase(await platform.openAppDatabase('yummealprep.db'));

  /// Opens an empty database that lives in memory, for tests.
  static Future<AppDatabase> inMemory() async => AppDatabase(
    await newDatabaseFactoryMemory().openDatabase('yummealprep.db'),
  );

  Future<void> close() => db.close();
}
