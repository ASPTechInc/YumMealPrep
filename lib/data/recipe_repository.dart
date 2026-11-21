// Project imports:
import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/data/choice_list_repository.dart';
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
}
