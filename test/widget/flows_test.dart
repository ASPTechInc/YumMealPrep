// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

// Project imports:
import 'package:yummealprep/app.dart';
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/sample_data.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/planned_meal.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/dates.dart';
import 'package:yummealprep/widgets/form_fields.dart';
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
    final sides = find.byType(SideDishesField);
    await tester.ensureVisible(sides);
    await tester.pumpAndSettle();
    await tester.tap(sides);
    await tester.pumpAndSettle();

    // The list is searchable, and a name that is not listed can be added.
    await tester.enterText(find.byType(TextField).last, 'cole');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Toast'), findsNothing);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Coleslaw'));
    await tester.enterText(find.byType(TextField).last, 'Pickled Onions');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add "Pickled Onions"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Coleslaw'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settle(tester);

    final meals = await db(tester, services.meals.getAll);
    final meal = meals.singleWhere((meal) => meal.name == 'Curry Goat');
    expect(meal.image, isNull);
    expect(meal.drink, 'Sorrel');
    expect(meal.sideDishes, ['Coleslaw', 'Pickled Onions']);
    expect(find.text('Meal added'), findsOneWidget);
  });

  testWidgets('manages the side dishes the meal form offers', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Browse'));
    await settle(tester);
    await tester.tap(find.text('Add meal'));
    await settle(tester);

    final manage = find.text('Manage side dishes');
    await tester.ensureVisible(manage);
    await tester.pumpAndSettle();
    await tester.tap(manage);
    await settle(tester);

    // The sample data's side dishes are listed.
    expect(find.text('Coleslaw'), findsOneWidget);

    await tester.tap(find.text('Add side dish'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Pickled Onions');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Pickled Onions'), findsOneWidget);

    await tester.tap(find.text('Coleslaw'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Red Coleslaw');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Red Coleslaw'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'onion');
    await tester.pumpAndSettle();
    expect(find.text('Red Coleslaw'), findsNothing);
    expect(find.text('Pickled Onions'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await settle(tester);
    expect(
      await db(tester, services.sideDishes.getAll),
      isNot(contains('Pickled Onions')),
    );

    // Back in the form, the dropdown offers the renamed side dish.
    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.byType(SideDishesField));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Red Coleslaw'), findsOne);
    expect(find.widgetWithText(CheckboxListTile, 'Coleslaw'), findsNothing);
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

  testWidgets("copies a day's meal by holding and dragging across days", (
    tester,
  ) async {
    final today = dateOnly(DateTime.now());
    final meal = (await db(tester, services.meals.getAll)).first;
    await db(
      tester,
      () => services.mealPlan.add(
        mealId: meal.id,
        date: today,
        slot: MealType.lunch,
      ),
    );
    await startApp(tester);

    // The two-week view always shows today and at least the next six days.
    Finder dayCell(DateTime day) => find.descendant(
      of: find.byType(TableCalendar<PlannedMeal>),
      matching: find.text('${day.day}'),
    );
    final gesture = await tester.startGesture(tester.getCenter(dayCell(today)));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(
      tester.getCenter(
        dayCell(DateTime(today.year, today.month, today.day + 1)),
      ),
    );
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(
        dayCell(DateTime(today.year, today.month, today.day + 2)),
      ),
    );
    await tester.pump();
    await gesture.up();
    await settle(tester);

    expect(find.text('Meal copied to 2 days'), findsOneWidget);
    final plan = await db(tester, services.mealPlan.getAll);
    expect(plan.map((entry) => entry.date), [
      today,
      DateTime(today.year, today.month, today.day + 1),
      DateTime(today.year, today.month, today.day + 2),
    ]);
    expect(plan.map((entry) => entry.mealId).toSet(), {meal.id});

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await db(tester, services.mealPlan.getAll), hasLength(1));
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
