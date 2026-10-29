import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import 'package:yummealprep/app.dart';
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/sample_data.dart';

AppServices? _services;

/// Starts the real app on the device, with its real database and picture
/// storage emptied first so every test begins from a fresh install.
Future<AppServices> startApp(
  WidgetTester tester, {
  bool sampleData = true,
  Future<void> Function(AppServices services)? setUp,
}) async {
  final services = _services ??= await AppServices.open();
  final db = services.database.db;
  await db.transaction((transaction) async {
    for (final store in [
      AppDatabase.meals,
      AppDatabase.recipes,
      AppDatabase.mealPlan,
    ]) {
      await store.delete(transaction);
    }
    await AppDatabase.settings.delete(transaction);
  });
  await services.settings.setThemeMode(ThemeMode.light);
  if (sampleData) {
    await SampleData(services.database, services.settings).addIfNeeded();
  }
  await setUp?.call(services);

  await tester.pumpWidget(YumMealPrepApp(services: services));
  await tester.pumpAndSettle();
  return services;
}
