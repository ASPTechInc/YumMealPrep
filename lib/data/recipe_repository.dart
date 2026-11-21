// Package imports:
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/data/choice_list_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/services/image_store.dart';

class RecipeRepository extends CatalogueRepository<Recipe> {
  RecipeRepository(AppDatabase database, ImageStore images)
    : sideDishes = ChoiceListRepository(database, ChoiceList.sideDishes),
      super(database, AppDatabase.recipes, images);

  final ChoiceListRepository sideDishes;

  @override
  Recipe fromMap(String id, Map<String, Object?> map) =>
      Recipe.fromMap(id, map);

  /// A recipe with its Side dish switch on is offered as a side dish for
  /// meals too.
  @override
  Future<void> save(Recipe item) async {
    await super.save(item);
    if (item.isSideDish) await sideDishes.add([item.name]);
  }

  /// Saves [item] and makes it the recipe of exactly the meals in
  /// [mealIds]. The link is stored on the meals (see `Meal.recipeIds`), so
  /// the recipe is added to or taken off each meal as needed, all in one
  /// transaction.
  Future<void> saveWithMeals(Recipe item, Set<String> mealIds) async {
    await save(item);
    await db.transaction(
      (transaction) => _setMeals(transaction, item.id, mealIds),
    );
  }

  /// Deleting a recipe also takes it off the meals that use it.
  @override
  Future<void> deleteRecord(String id) => db.transaction((transaction) async {
    await store.record(id).delete(transaction);
    await _setMeals(transaction, id, const {});
  });

  static Future<void> _setMeals(
    Transaction transaction,
    String recipeId,
    Set<String> mealIds,
  ) async {
    for (final record in await AppDatabase.meals.find(transaction)) {
      final meal = Meal.fromMap(record.key, record.value);
      final linked = meal.recipeIds.contains(recipeId);
      final wanted = mealIds.contains(meal.id);
      if (linked == wanted) continue;
      await AppDatabase.meals.record(meal.id).update(transaction, {
        'recipeIds': wanted
            ? [...meal.recipeIds, recipeId]
            : meal.recipeIds.where((id) => id != recipeId).toList(),
      });
    }
  }
}
