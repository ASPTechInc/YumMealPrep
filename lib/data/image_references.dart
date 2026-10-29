import 'package:sembast/sembast.dart';

import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/services/image_store.dart';

/// Every image source the stored meals and recipes refer to.
Future<Set<String>> imagesInUse(DatabaseClient db) async => {
  for (final record in await AppDatabase.meals.find(db))
    ...Meal.fromMap(record.key, record.value).imageSources,
  for (final record in await AppDatabase.recipes.find(db))
    ...Recipe.fromMap(record.key, record.value).imageSources,
};

/// Deletes the pictures in [candidates] that the app saved and that no meal
/// or recipe refers to any more.
///
/// Pictures are stored once and can be shared (see `FileImageStore`), so a
/// picture is only deleted when nothing uses it, never just because one
/// item stopped using it.
Future<void> deleteUnusedImages(
  DatabaseClient db,
  ImageStore images,
  Iterable<String> candidates,
) async {
  final owned = candidates.where(images.owns).toSet();
  if (owned.isEmpty) return;
  final inUse = await imagesInUse(db);
  for (final source in owned.difference(inUse)) {
    await images.delete(source);
  }
}
