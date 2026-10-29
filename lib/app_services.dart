import 'package:flutter/widgets.dart';

import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/backup_service.dart';
import 'package:yummealprep/data/image_references.dart' as references;
import 'package:yummealprep/data/meal_plan_repository.dart';
import 'package:yummealprep/data/meal_repository.dart';
import 'package:yummealprep/data/recipe_repository.dart';
import 'package:yummealprep/data/settings_repository.dart';
import 'package:yummealprep/services/image_store.dart';

/// Everything the screens need to read and change the app's data.
class AppServices {
  AppServices({
    required this.database,
    required this.images,
    required this.settings,
  }) : meals = MealRepository(database, images),
       recipes = RecipeRepository(database, images),
       mealPlan = MealPlanRepository(database),
       backup = BackupService(database, images);

  final AppDatabase database;
  final ImageStore images;
  final SettingsRepository settings;
  final MealRepository meals;
  final RecipeRepository recipes;
  final MealPlanRepository mealPlan;
  final BackupService backup;

  static Future<AppServices> open() async {
    final database = await AppDatabase.open();
    return AppServices(
      database: database,
      images: await ImageStore.open(),
      settings: await SettingsRepository.load(database),
    );
  }

  /// Services backed by an in-memory database, for tests.
  static Future<AppServices> inMemory() async {
    final database = await AppDatabase.inMemory();
    return AppServices(
      database: database,
      images: DataUriImageStore(),
      settings: await SettingsRepository.load(database),
    );
  }

  /// Deletes the pictures in [sources] that the app saved and nothing uses.
  Future<void> deleteUnusedImages(Iterable<String> sources) =>
      references.deleteUnusedImages(database.db, images, sources);

  Future<void> close() async {
    settings.dispose();
    await database.close();
  }
}

/// Makes [AppServices] available to every screen below it.
class AppScope extends InheritedWidget {
  const AppScope({required this.services, required super.child, super.key});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this widget.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
