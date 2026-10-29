import 'package:sembast/sembast.dart';

import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/data/image_references.dart';
import 'package:yummealprep/models/catalogue_item.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/services/image_store.dart';
import 'package:yummealprep/utils/search.dart';

/// Stores meals or recipes and keeps the pictures they use tidy.
abstract class CatalogueRepository<T extends CatalogueItem> {
  CatalogueRepository(this.database, this.store, this.images);

  final AppDatabase database;
  final RecordStore store;
  final ImageStore images;

  Database get db => database.db;

  T fromMap(String id, Map<String, Object?> map);

  /// Every item, sorted by name, updated whenever anything changes.
  Stream<List<T>> watchAll() => store.query().onSnapshots(db).map(_toItems);

  /// One item, or `null` once it has been deleted.
  Stream<T?> watch(String id) => store
      .record(id)
      .onSnapshot(db)
      .map((snapshot) => snapshot == null ? null : _toItem(snapshot));

  Future<List<T>> getAll() async => _toItems(await store.find(db));

  Future<T?> get(String id) async {
    final value = await store.record(id).get(db);
    return value == null ? null : fromMap(id, value);
  }

  /// Adds [item], or replaces the stored item with the same id. Pictures the
  /// previous version used are deleted once nothing else uses them.
  Future<void> save(T item) async {
    final previous = await get(item.id);
    await store.record(item.id).put(db, item.toMap());
    if (previous != null) {
      await deleteUnusedImages(db, images, previous.imageSources);
    }
  }

  Future<void> setFavourite(String id, {required bool favourite}) =>
      store.record(id).update(db, {'isFavourite': favourite});

  Future<void> delete(String id) async {
    final item = await get(id);
    await deleteRecord(id);
    if (item != null) await deleteUnusedImages(db, images, item.imageSources);
  }

  /// Removes the record itself. Subclasses override this to remove records
  /// that depend on it in the same transaction.
  Future<void> deleteRecord(String id) => store.record(id).delete(db);

  T _toItem(RecordSnapshot<String, Map<String, Object?>> snapshot) =>
      fromMap(snapshot.key, snapshot.value);

  List<T> _toItems(
    List<RecordSnapshot<String, Map<String, Object?>>> snapshots,
  ) => snapshots.map(_toItem).toList()..sort(compareByName);
}

int compareByName(CatalogueItem a, CatalogueItem b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

/// Narrows [items] down to one [type], to favourites, and to those that
/// match a search [query]. Order is kept.
List<T> filterItems<T extends CatalogueItem>(
  Iterable<T> items, {
  MealType? type,
  bool favouritesOnly = false,
  String query = '',
}) => items
    .where(
      (item) =>
          (type == null || item.type == type) &&
          (!favouritesOnly || item.isFavourite) &&
          matchesQuery(query, item.searchableText),
    )
    .toList();

/// How many of [items] there are of each type. Every type is present.
Map<MealType, int> countByType(Iterable<CatalogueItem> items) {
  final counts = {for (final type in MealType.values) type: 0};
  for (final item in items) {
    counts[item.type] = counts[item.type]! + 1;
  }
  return counts;
}
