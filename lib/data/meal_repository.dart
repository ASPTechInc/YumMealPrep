import 'package:sembast/sembast.dart';

import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/services/image_store.dart';

class MealRepository extends CatalogueRepository<Meal> {
  MealRepository(AppDatabase database, ImageStore images)
    : super(database, AppDatabase.meals, images);

  @override
  Meal fromMap(String id, Map<String, Object?> map) => Meal.fromMap(id, map);

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
