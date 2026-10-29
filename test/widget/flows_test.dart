import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yummealprep/app.dart';
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/sample_data.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// End-to-end user flows through the screens, on an in-memory database.
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
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    }
  }

  Future<void> startApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(YumMealPrepApp(services: services));
    await settle(tester);
  }

  Future<T> db<T>(WidgetTester tester, Future<T> Function() action) async =>
      (await tester.runAsync(action)) as T;

  testWidgets('adds a meal without a picture', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Browse'));
    await settle(tester);
    await tester.tap(find.text('Add meal'));
    await settle(tester);

    // A name is the only required field.
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Name is required'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name *'),
      'Curry Goat',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Drink'),
      'Sorrel',
    );
    final coleslaw = find.widgetWithText(FilterChip, 'Coleslaw');
    await tester.ensureVisible(coleslaw);
    await tester.pumpAndSettle();
    await tester.tap(coleslaw);
    await tester.tap(find.text('Save'));
    await settle(tester);

    final meals = await db(tester, services.meals.getAll);
    final meal = meals.singleWhere((meal) => meal.name == 'Curry Goat');
    expect(meal.image, isNull);
    expect(meal.drink, 'Sorrel');
    expect(meal.sideDishes, ['Coleslaw']);
    expect(find.text('Meal added'), findsOneWidget);
  });

  testWidgets('leaving a form with changes asks first', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Browse'));
    await settle(tester);
    await tester.tap(find.text('Add meal'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name *'),
      'Half-typed',
    );
    await tester.pump();
    // The system back button.
    await tester.binding.handlePopRoute();
    await settle(tester);

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    expect(find.text('Browse'), findsWidgets);
    final meals = await db(tester, services.meals.getAll);
    expect(meals.map((meal) => meal.name), isNot(contains('Half-typed')));
  });

  testWidgets('plans a meal, removes it and undoes the removal', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text('Plan a meal').first);
    await settle(tester);

    final lunch = find.widgetWithText(ChoiceChip, 'Lunch');
    await tester.ensureVisible(lunch);
    await tester.pumpAndSettle();
    await tester.tap(lunch);
    await settle(tester);
    await tester.tap(find.text('Fish & Chips').last);
    await settle(tester);

    expect(find.text('1 meal'), findsOneWidget);
    expect(await db(tester, services.mealPlan.getAll), hasLength(1));

    await tester.tap(find.byTooltip('Remove from plan'));
    await settle(tester);
    expect(find.text('No meals planned for this day.'), findsOneWidget);
    expect(await db(tester, services.mealPlan.getAll), isEmpty);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('1 meal'), findsOneWidget);
  });

  testWidgets('favourites a recipe and unfavourites it by swiping', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text('Search'));
    await settle(tester);
    await tester.tap(find.text('Recipes'));
    await settle(tester);
    await tester.tap(find.text('Lasagne'));
    await settle(tester);
    await tester.tap(find.byTooltip('Add to favourites'));
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('Favourites'));
    await settle(tester);
    await tester.tap(find.widgetWithText(Tab, 'Recipes'));
    await settle(tester);
    expect(find.text('Lasagne'), findsOneWidget);

    await tester.drag(find.text('Lasagne'), const Offset(-600, 0));
    await settle(tester);
    expect(find.text('Lasagne removed from favourites'), findsOneWidget);
    final lasagne = (await db(
      tester,
      services.recipes.getAll,
    )).singleWhere((recipe) => recipe.name == 'Lasagne');
    expect(lasagne.isFavourite, isFalse);
  });

  testWidgets('edits and then deletes a meal', (tester) async {
    await startApp(tester);
    final id = (await db(
      tester,
      services.meals.getAll,
    )).singleWhere((meal) => meal.name == 'Fish & Chips').id;
    await db(
      tester,
      () => services.mealPlan.add(
        mealId: id,
        date: DateTime.now(),
        slot: MealType.lunch,
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Fish & Chips'));
    await settle(tester);
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.tap(find.text('Edit'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name *'),
      'Fish & Chips with Peas',
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Fish & Chips with Peas'), findsWidgets);

    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(await db(tester, () => services.meals.get(id)), isNull);
    // Deleting the meal also took it out of the plan.
    expect(await db(tester, services.mealPlan.getAll), isEmpty);
    expect(find.text('No meals planned for this day.'), findsOneWidget);
  });

  testWidgets('shows the placeholder for missing or broken pictures', (
    tester,
  ) async {
    await db(
      tester,
      () => services.meals.save(
        const Meal(
          id: 'broken',
          name: 'Broken Picture',
          type: MealType.dinner,
          image: 'https://example.com/never-downloaded.jpg',
        ),
      ),
    );
    await startApp(tester);
    await tester.tap(find.text('Search'));
    await settle(tester);
    await tester.enterText(find.byType(SearchBar), 'broken');
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(ItemImage),
        matching: find.byIcon(Icons.no_photography_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switches to the dark theme from the side menu', (tester) async {
    await startApp(tester);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await settle(tester);
    await tester.tap(find.text('Dark'));
    await settle(tester);

    expect(services.settings.themeMode.value, ThemeMode.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('opens the photo credits', (tester) async {
    await startApp(tester);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Photo credits'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Photo credits'));
    await settle(tester);
    expect(find.textContaining('Wikimedia Commons'), findsWidgets);
  });
}
