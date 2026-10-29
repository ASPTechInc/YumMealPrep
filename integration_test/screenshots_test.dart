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
/// phoneScreenshots/, using a set of everyday dishes and the bundled photos.
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
    await tester.tap(find.text('Pelau'));
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

/// Everyday dishes for the screenshots, using the bundled photos.
Future<void> _addDemoData(AppServices services) async {
  Meal meal(
    String id,
    String name,
    MealType type,
    String photo,
    String drink, [
    List<String> sides = const [],
  ]) => Meal(
    id: id,
    name: name,
    type: type,
    drink: drink,
    sideDishes: sides,
    image: 'assets/images/meals/$photo.webp',
    description: _descriptions[name] ?? '',
  );
  final meals = [
    meal(
      'demo-french-toast',
      'French Toast',
      MealType.breakfast,
      'french-toast',
      'Chocolate Tea',
    ),
    meal('demo-pelau', 'Pelau', MealType.lunch, 'pelau', 'Sorrel', [
      'Coleslaw',
    ]),
    meal('demo-pizza', 'Pizza', MealType.dinner, 'pizza', 'Water'),
    meal(
      'demo-roti',
      'Roti & Curry Chicken',
      MealType.lunch,
      'roti-and-curry-chicken',
      'Mauby',
    ),
    meal(
      'demo-callaloo',
      'Callaloo Soup',
      MealType.lunch,
      'callaloo-soup',
      'Juice',
    ),
    meal(
      'demo-macaroni-pie',
      'Macaroni Pie & Fried Chicken',
      MealType.lunch,
      'macaroni-pie-and-fried-chicken',
      'Juice',
      ['Coleslaw'],
    ),
    meal('demo-chowmein', 'Chowmein', MealType.dinner, 'chowmein', 'Juice'),
    meal(
      'demo-pumpkin-soup',
      'Pumpkin Soup',
      MealType.dinner,
      'pumpkin-soup',
      'Ginger Tea',
    ),
  ];
  for (final item in meals) {
    await services.meals.save(item);
  }
  await services.meals.setFavourite('demo-pelau', favourite: true);

  await services.recipes.save(
    const Recipe(
      id: 'demo-jerk-chicken',
      name: 'Jerk Chicken',
      type: MealType.dinner,
      description:
          'Chicken marinated in a hot, spicy jerk seasoning, then '
          'grilled slowly until smoky and tender.',
      ingredients: [
        'Chicken thighs',
        'Jerk seasoning',
        'Scotch bonnet pepper',
        'Thyme',
        'Lime',
      ],
      instructions: [
        'Season the chicken and leave it overnight.',
        'Grill over a medium heat, turning often, for about an hour.',
      ],
      preparationMinutes: 15,
      cookingMinutes: 60,
      servings: 6,
      image: 'assets/images/recipes/jerk-chicken.webp',
    ),
  );

  final today = DateTime.now();
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);
  for (final (offset, id, slot) in [
    (0, 'demo-french-toast', MealType.breakfast),
    (0, 'demo-pelau', MealType.lunch),
    (0, 'demo-pizza', MealType.dinner),
    (1, 'demo-roti', MealType.lunch),
    (1, 'demo-chowmein', MealType.dinner),
    (2, 'demo-callaloo', MealType.lunch),
    (3, 'demo-macaroni-pie', MealType.lunch),
    (3, 'demo-pumpkin-soup', MealType.dinner),
  ]) {
    await services.mealPlan.add(mealId: id, date: day(offset), slot: slot);
  }
}

const _descriptions = {
  'Pelau':
      'Rice cooked with chicken, pigeon peas and vegetables, with the '
      'meat first browned in sugar. A one-pot Caribbean favourite.',
  'French Toast':
      'Bread soaked in beaten egg, milk and cinnamon, then '
      'fried until golden.',
  'Pizza': 'A thin crust topped with tomato sauce, mozzarella and basil.',
};
