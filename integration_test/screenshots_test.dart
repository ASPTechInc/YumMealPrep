import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';

import 'support.dart';

/// Takes the store screenshots in fastlane/metadata/android/en-GB/images/
/// phoneScreenshots/, using a set of everyday dishes and the bundled photos
/// (see `_addDemoData`).
///
/// Run on a phone emulator:
///   `flutter drive --driver=test_driver/integration_test.dart`
///   `--target=integration_test/screenshots_test.dart -d <device>`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    // Give pictures time to decode before capturing.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('store screenshots', (tester) async {
    await startApp(tester, setUp: _addDemoData);
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await shot(tester, '1');

    await tester.tap(find.text('Browse'));
    await shot(tester, '2');

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fried Shrimp, Rice & Beans'));
    await shot(tester, '3');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lasagne'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await shot(tester, '4');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'chicken');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meals'));
    await shot(tester, '5');

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan a meal').first);
    await shot(tester, '6');
    await tester.tapAt(const Offset(20, 60));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(tester.view.physicalSize.width / 3, 300));
    await shot(tester, '7');
  });
}

/// Everyday dishes for the screenshots. Most catalogue photos are not
/// bundled (they come in a backup), so these use only the pictures that
/// always ship with the app: the category photos and the sample data's.
Future<void> _addDemoData(AppServices services) async {
  Meal meal(
    String id,
    String name,
    MealType type,
    String image,
    String drink, [
    List<String> sides = const [],
  ]) => Meal(
    id: id,
    name: name,
    type: type,
    drink: drink,
    sideDishes: sides,
    image: 'assets/images/$image.webp',
    description: _descriptions[name] ?? '',
  );
  final meals = [
    meal(
      'demo-eggs-on-toast',
      'Eggs on Toast',
      MealType.breakfast,
      'categories/breakfast',
      'Chocolate Tea',
    ),
    meal(
      'demo-shrimp',
      'Fried Shrimp, Rice & Beans',
      MealType.lunch,
      'categories/lunch',
      'Sorrel',
      ['Tossed Salad'],
    ),
    meal(
      'demo-roast-chicken',
      'Roast Chicken Dinner',
      MealType.dinner,
      'categories/dinner',
      'Water',
      ['Roast Potatoes', 'Coleslaw'],
    ),
    meal(
      'demo-lasagne',
      'Beef Lasagne',
      MealType.dinner,
      'recipes/lasagne',
      'Juice',
      ['Garlic Bread'],
    ),
    meal(
      'demo-platter',
      'Fried Chicken Platter',
      MealType.appetisers,
      'categories/appetisers',
      'Mauby',
    ),
    meal(
      'demo-chocolate-cake',
      'Chocolate Cake',
      MealType.dessert,
      'categories/dessert',
      'Milk',
    ),
    meal(
      'demo-smoothies',
      'Berry & Green Smoothies',
      MealType.smoothies,
      'categories/smoothies',
      '',
    ),
  ];
  for (final item in meals) {
    await services.meals.save(item);
  }
  await services.meals.setFavourite('demo-shrimp', favourite: true);

  await services.recipes.save(
    const Recipe(
      id: 'demo-chocolate-cake',
      name: 'Chocolate Cake',
      type: MealType.dessert,
      description:
          'Layers of moist chocolate sponge and cream, finished with '
          'cocoa and a drizzle of chocolate sauce.',
      ingredients: [
        'Flour',
        'Cocoa powder',
        'Sugar',
        'Eggs',
        'Butter',
        'Double cream',
      ],
      instructions: [
        'Bake the sponge and leave it to cool.',
        'Slice it into layers and fill with whipped cream.',
        'Dust with cocoa and drizzle with chocolate sauce.',
      ],
      preparationMinutes: 30,
      cookingMinutes: 35,
      servings: 8,
      image: 'assets/images/categories/dessert.webp',
    ),
  );

  final today = DateTime.now();
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);
  // Fish & Chips and Pancake & Scrambled Eggs come from the sample data.
  for (final (offset, id, slot) in [
    (0, 'demo-eggs-on-toast', MealType.breakfast),
    (0, 'demo-shrimp', MealType.lunch),
    (0, 'demo-roast-chicken', MealType.dinner),
    (1, 'i9T9zZ2nxAN7gfz2iSLE', MealType.breakfast),
    (1, 'EydGfAfwAR7vHM3yXmJ4', MealType.lunch),
    (1, 'demo-lasagne', MealType.dinner),
    (2, 'demo-platter', MealType.appetisers),
    (2, 'demo-chocolate-cake', MealType.dessert),
  ]) {
    await services.mealPlan.add(mealId: id, date: day(offset), slot: slot);
  }
}

const _descriptions = {
  'Fried Shrimp, Rice & Beans':
      'Crispy fried shrimp on lettuce and tomato, with yellow rice and '
      'black beans on the side.',
  'Roast Chicken Dinner':
      'A whole roast chicken with all the trimmings, made for sharing '
      'round the table.',
  'Eggs on Toast': 'Fried eggs on buttered toast, ready in minutes.',
};
