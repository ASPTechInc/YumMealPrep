import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/services/image_store.dart';

class RecipeRepository extends CatalogueRepository<Recipe> {
  RecipeRepository(AppDatabase database, ImageStore images)
    : super(database, AppDatabase.recipes, images);

  @override
  Recipe fromMap(String id, Map<String, Object?> map) =>
      Recipe.fromMap(id, map);
}
