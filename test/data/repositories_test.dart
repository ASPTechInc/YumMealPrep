// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/data/meal_plan_repository.dart';
import 'package:yummealprep/data/settings_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';

void main() {
  late AppServices services;

  setUp(() async => services = await AppServices.inMemory());
  tearDown(() => services.close());

  const pelau = Meal(id: 'pelau', name: 'Pelau', type: MealType.lunch);
  const oats = Meal(
    id: 'oats',
    name: 'oats porridge',
    type: MealType.breakfast,
    drink: 'Tea',
  );
  const cake = Meal(id: 'cake', name: 'Carrot Cake', type: MealType.dessert);

  group('MealRepository', () {
    test('saves, reads and lists meals sorted by name', () async {
      await services.meals.save(pelau);
      await services.meals.save(oats);
      await services.meals.save(cake);

      expect(await services.meals.get('pelau'), pelau);
      final names = (await services.meals.getAll()).map((m) => m.name);
      // Sorting ignores case.
      expect(names, ['Carrot Cake', 'oats porridge', 'Pelau']);
    });

    test('watch emits changes and null once deleted', () async {
      final updates = services.meals.watch('pelau');
      final expectation = expectLater(
        updates,
        emitsInOrder([null, pelau, pelau.copyWith(isFavourite: true), null]),
      );
      await pumpEventQueue();
      await services.meals.save(pelau);
      await pumpEventQueue();
      await services.meals.setFavourite('pelau', favourite: true);
      await pumpEventQueue();
      await services.meals.delete('pelau');
      await expectation;
    });

    test('deleting a meal removes it from the meal plan', () async {
      await services.meals.save(pelau);
      await services.meals.save(oats);
      await services.mealPlan.add(
        mealId: 'pelau',
        date: DateTime(2026, 11, 2),
        slot: MealType.lunch,
      );
      await services.mealPlan.add(
        mealId: 'oats',
        date: DateTime(2026, 11, 2),
        slot: MealType.breakfast,
      );

      await services.meals.delete('pelau');

      final plan = await services.mealPlan.getAll();
      expect(plan.map((entry) => entry.mealId), ['oats']);
    });
  });

  group('RecipeRepository', () {
    const rice = Recipe(id: 'rice', name: 'Rice', type: MealType.lunch);
    const stew = Recipe(id: 'stew', name: 'Stew', type: MealType.lunch);

    test('saveWithMeals links the recipe to exactly those meals', () async {
      await services.meals.save(pelau.copyWith(recipeIds: ['stew']));
      await services.meals.save(oats.copyWith(recipeIds: ['rice']));
      await services.meals.save(cake);

      await services.recipes.saveWithMeals(rice, {'pelau', 'cake'});

      expect((await services.recipes.get('rice'))?.name, 'Rice');
      // Added after the meal's other recipes; other links are left alone.
      expect((await services.meals.get('pelau'))!.recipeIds, ['stew', 'rice']);
      expect((await services.meals.get('cake'))!.recipeIds, ['rice']);
      expect((await services.meals.get('oats'))!.recipeIds, isEmpty);
    });

    test('deleting a recipe takes it off the meals that use it', () async {
      await services.recipes.save(rice);
      await services.recipes.save(stew);
      await services.meals.save(pelau.copyWith(recipeIds: ['rice', 'stew']));

      await services.recipes.delete('rice');

      expect((await services.meals.get('pelau'))!.recipeIds, ['stew']);
    });
  });

  group('filterItems and countByType', () {
    const meals = [pelau, oats, cake];

    test('filters by type, favourites and query', () {
      expect(filterItems(meals, type: MealType.lunch), [pelau]);
      expect(filterItems(meals, query: 'tea'), [oats]);
      expect(
        filterItems([
          ...meals,
          pelau.copyWith(isFavourite: true),
        ], favouritesOnly: true),
        [pelau.copyWith(isFavourite: true)],
      );
    });

    test('counts every type, including empty ones', () {
      final counts = countByType(meals);
      expect(counts, hasLength(MealType.values.length));
      expect(counts[MealType.lunch], 1);
      expect(counts[MealType.smoothies], 0);
    });

    test('searches recipe ingredients', () {
      const recipe = Recipe(
        id: 'r',
        name: 'Rice',
        type: MealType.lunch,
        ingredients: ['Turmeric'],
      );
      expect(filterItems([recipe], query: 'turmeric'), [recipe]);
    });
  });

  group('MealPlanRepository', () {
    test('a day can hold several meals, and a meal several days', () async {
      final monday = DateTime(2026, 11, 2, 15, 45);
      final tuesday = DateTime(2026, 11, 3);
      await services.mealPlan.add(
        mealId: 'pelau',
        date: monday,
        slot: MealType.dinner,
      );
      await services.mealPlan.add(
        mealId: 'oats',
        date: monday,
        slot: MealType.breakfast,
      );
      await services.mealPlan.add(
        mealId: 'pelau',
        date: tuesday,
        slot: MealType.lunch,
      );

      final days = groupByDay(await services.mealPlan.getAll());
      final mondayEntries = days[DateTime(2026, 11, 2)]!;
      // Times are dropped, and each day is ordered by slot.
      expect(mondayEntries.map((entry) => entry.slot), [
        MealType.breakfast,
        MealType.dinner,
      ]);
      expect(days[tuesday]!.single.mealId, 'pelau');
    });

    test('remove deletes one entry', () async {
      final entry = await services.mealPlan.add(
        mealId: 'pelau',
        date: DateTime(2026, 11, 2),
        slot: MealType.lunch,
      );
      await services.mealPlan.remove(entry.id);
      expect(await services.mealPlan.getAll(), isEmpty);
    });

    test('copyToDays skips a meal a day already has in that slot', () async {
      final monday = DateTime(2026, 11, 2);
      final tuesday = DateTime(2026, 11, 3);
      final wednesday = DateTime(2026, 11, 4);
      final lunch = await services.mealPlan.add(
        mealId: 'pelau',
        date: monday,
        slot: MealType.lunch,
      );
      await services.mealPlan.add(
        mealId: 'pelau',
        date: tuesday,
        slot: MealType.lunch,
      );
      final plan = groupByDay(await services.mealPlan.getAll());

      final copies = copyToDays([lunch], [tuesday, wednesday], plan);
      expect(copies.map((copy) => copy.date), [wednesday]);

      await services.mealPlan.addAll(copies);
      expect(await services.mealPlan.getAll(), hasLength(3));
      await services.mealPlan.removeAll(copies.map((copy) => copy.id));
      expect(await services.mealPlan.getAll(), hasLength(2));
    });
  });

  group('SettingsRepository', () {
    test('remembers the theme', () async {
      expect(services.settings.themeMode.value, ThemeMode.system);
      await services.settings.setThemeMode(ThemeMode.dark);

      final reloaded = await SettingsRepository.load(services.database);
      expect(reloaded.themeMode.value, ThemeMode.dark);
      reloaded.dispose();
    });
  });
}
