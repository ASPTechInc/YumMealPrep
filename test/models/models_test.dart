import 'package:flutter_test/flutter_test.dart';

import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/planned_meal.dart';
import 'package:yummealprep/models/recipe.dart';

void main() {
  test('a meal survives a round trip through storage', () {
    const meal = Meal(
      id: 'm1',
      name: 'Pelau',
      type: MealType.lunch,
      description: 'Rice cooked with meat and vegetables.',
      drink: 'Sorrel',
      sideDishes: ['Coleslaw'],
      image: 'local:images/pelau.jpg',
      nutritionFactImages: ['local:images/label.jpg'],
      isFavourite: true,
    );
    expect(Meal.fromMap(meal.id, meal.toMap()), meal);
  });

  test('a recipe survives a round trip through storage', () {
    const recipe = Recipe(
      id: 'r1',
      name: 'White Rice',
      type: MealType.lunch,
      ingredients: ['2 cups of rice', '1 tsp salt'],
      instructions: ['Boil the water', 'Add the rice'],
      preparationMinutes: 5,
      cookingMinutes: 20,
      servings: 4,
      isSideDish: true,
    );
    expect(Recipe.fromMap(recipe.id, recipe.toMap()), recipe);
    expect(recipe.totalMinutes, 25);
  });

  test('a planned meal survives a round trip through storage', () {
    final entry = PlannedMeal(
      id: 'p1',
      mealId: 'm1',
      date: DateTime(2026, 10, 28),
      slot: MealType.dinner,
    );
    expect(entry.toMap()['day'], '2026-10-28');
    expect(PlannedMeal.fromMap(entry.id, entry.toMap()), entry);
  });

  test('records with missing or mistyped values still load', () {
    final meal = Meal.fromMap('m1', {
      'name': 'Soup',
      'type': 'Lunch', // a label, as older data stored it
      'sideDishes': ['Bread', 3, '', null],
      'isFavourite': 'yes',
    });
    expect(meal.type, MealType.lunch);
    expect(meal.sideDishes, ['Bread']);
    expect(meal.isFavourite, isFalse);
    expect(meal.image, isNull);

    final recipe = Recipe.fromMap('r1', {
      'servings': '4',
      'cookingMinutes': 9.6,
    });
    expect(recipe.name, '');
    expect(recipe.servings, 4);
    expect(recipe.cookingMinutes, 10);
    expect(recipe.totalMinutes, 10);
  });

  test('copyWith can clear the picture', () {
    const meal = Meal(id: 'm1', name: 'Soup', type: MealType.lunch, image: 'a');
    expect(meal.copyWith(image: () => null).image, isNull);
    expect(meal.copyWith(name: 'Stew').image, 'a');
  });

  test('imageSources lists every picture a meal uses', () {
    const meal = Meal(
      id: 'm1',
      name: 'Soup',
      type: MealType.lunch,
      image: 'a',
      nutritionFactImages: ['b', 'c'],
    );
    expect(meal.imageSources, ['a', 'b', 'c']);
  });
}
