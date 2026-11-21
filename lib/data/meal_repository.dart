// Package imports:
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/data/choice_list_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/services/image_store.dart';

class MealRepository extends CatalogueRepository<Meal> {
  MealRepository(AppDatabase database, ImageStore images)
    : sideDishes = ChoiceListRepository(database, ChoiceList.sideDishes),
      drinks = ChoiceListRepository(database, ChoiceList.drinks),
      super(database, AppDatabase.meals, images);

  final ChoiceListRepository sideDishes;
  final ChoiceListRepository drinks;

  @override
  Meal fromMap(String id, Map<String, Object?> map) => Meal.fromMap(id, map);

  /// Side dishes and drinks typed into a meal are offered for the next one.
  @override
  Future<void> save(Meal item) async {
    await super.save(item);
    await sideDishes.add(item.sideDishes);
    await drinks.add([item.drink]);
  }

  /// Deleting a meal also takes it out of the meal plan.
  @override
  Future<void> deleteRecord(String id) => db.transaction((transaction) async {
    await store.record(id).delete(transaction);
    await AppDatabase.mealPlan.delete(
      transaction,
      finder: Finder(filter: Filter.equals('mealId', id)),
    );
  });
}
