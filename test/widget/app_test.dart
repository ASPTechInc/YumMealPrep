import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yummealprep/app.dart';
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/sample_data.dart';
import 'package:yummealprep/utils/constants.dart';

void main() {
  late AppServices services;

  setUp(() async {
    services = await AppServices.inMemory();
    await SampleData(
      services.database,
      services.settings,
    ).addFromJson(File(Constants.seedData).readAsStringSync());
  });
  tearDown(() => services.close());

  Future<void> settle(WidgetTester tester) async {
    // The database answers asynchronously, outside the fake test clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the meal planner', (tester) async {
    await tester.pumpWidget(YumMealPrepApp(services: services));
    await settle(tester);

    expect(find.text('Meal Planner'), findsOneWidget);
    expect(find.text('No meals planned for this day.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('browse shows a card for each category', (tester) async {
    await tester.pumpWidget(YumMealPrepApp(services: services));
    await settle(tester);

    await tester.tap(find.text('Browse'));
    await settle(tester);

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Smoothies'), findsOneWidget);
  });

  testWidgets('search finds recipes by name and ingredient', (tester) async {
    await tester.pumpWidget(YumMealPrepApp(services: services));
    await settle(tester);

    await tester.tap(find.text('Search'));
    await settle(tester);
    await tester.tap(find.text('Recipes'));
    await settle(tester);
    await tester.enterText(find.byType(SearchBar), 'banana');
    await settle(tester);

    expect(find.text('Banana Smoothie'), findsOneWidget);
    expect(find.text('Lasagne'), findsNothing);
  });

  testWidgets('opens a meal from a category and adds it to favourites', (
    tester,
  ) async {
    await tester.pumpWidget(YumMealPrepApp(services: services));
    await settle(tester);

    // Pushing a route from the tabs used to fail because every tab's
    // floating button shared the same hero tag.
    await tester.tap(find.text('Browse'));
    await settle(tester);
    await tester.tap(find.text('Lunch'));
    await settle(tester);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), 'fish');
    await settle(tester);
    await tester.tap(find.text('Fish & Chips'));
    await settle(tester);
    expect(find.text('Juice'), findsOneWidget);

    await tester.tap(find.byTooltip('Add to favourites'));
    await settle(tester);
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    final meals = await tester.runAsync(services.meals.getAll);
    expect(
      meals!.firstWhere((meal) => meal.name == 'Fish & Chips').isFavourite,
      isTrue,
    );
  });
}
