// Package imports:
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/recipe.dart';

/// The names offered when filling in a meal's side dishes or drink.
enum ChoiceList {
  sideDishes('Side dishes', 'side dish'),
  drinks('Drinks', 'drink');

  const ChoiceList(this.label, this.singular);

  final String label;
  final String singular;

  /// The names in [list] that [meals] and [recipes] already use, so nothing
  /// in use is missing from the list. A recipe counts as a side dish once
  /// its Side dish switch is on.
  static Map<ChoiceList, List<String>> usedBy(
    Iterable<Meal> meals,
    Iterable<Recipe> recipes,
  ) => {
    sideDishes: [
      for (final meal in meals) ...meal.sideDishes,
      for (final recipe in recipes)
        if (recipe.isSideDish) recipe.name,
    ],
    drinks: [for (final meal in meals) meal.drink],
  };
}

/// One [ChoiceList], kept in the database so it can be edited in the app
/// and carried in backups.
class ChoiceListRepository {
  ChoiceListRepository(this.database, this.list);

  static final StoreRef<String, Object?> _store = AppDatabase.choices;

  final AppDatabase database;
  final ChoiceList list;

  Database get _db => database.db;
  RecordRef<String, Object?> get _record => _store.record(list.name);

  /// The names, sorted A to Z, updated whenever they change.
  Stream<List<String>> watch() =>
      _record.onSnapshot(_db).map((snapshot) => _sorted(snapshot?.value));

  Future<List<String>> getAll([DatabaseClient? client]) async =>
      _sorted(await _record.get(client ?? _db));

  /// Whether the list has been saved yet. Copies of the app from before
  /// these lists existed have not saved one.
  Future<bool> exists([DatabaseClient? client]) =>
      _record.exists(client ?? _db);

  /// Adds [names] that are not in the list yet, ignoring case, so
  /// "coleslaw" does not end up beside "Coleslaw".
  Future<void> add(Iterable<String> names, [DatabaseClient? client]) async {
    final current = await getAll(client);
    await _save(merge(current, names), client);
  }

  /// Replaces the whole list with [names].
  Future<void> replace(Iterable<String> names, [DatabaseClient? client]) =>
      _save(merge(const [], names), client);

  Future<void> remove(String name) async {
    final current = await getAll();
    await _save(current.where((other) => other != name), null);
  }

  /// Renames [from] to [to] in the list and in every meal that uses it, so
  /// the meals keep matching the list. Returns how many meals changed.
  Future<int> rename(String from, String to) {
    final name = to.trim();
    return _db.transaction((transaction) async {
      final current = await getAll(transaction);
      await _save(
        merge(current.where((other) => other != from), [name]),
        transaction,
      );

      var changed = 0;
      for (final record in await AppDatabase.meals.find(transaction)) {
        final meal = Meal.fromMap(record.key, record.value);
        final updated = switch (list) {
          ChoiceList.sideDishes when meal.sideDishes.contains(from) =>
            meal.copyWith(
              sideDishes: merge(const [], [
                for (final side in meal.sideDishes) side == from ? name : side,
              ]),
            ),
          ChoiceList.drinks when meal.drink == from => meal.copyWith(
            drink: name,
          ),
          _ => null,
        };
        if (updated == null) continue;
        await AppDatabase.meals
            .record(meal.id)
            .put(transaction, updated.toMap());
        changed++;
      }
      return changed;
    });
  }

  Future<void> _save(Iterable<String> names, DatabaseClient? client) =>
      _record.put(client ?? _db, names.toList());

  /// [first] followed by the names in [more] it does not already have.
  /// Blank names are dropped and the first spelling of a name wins.
  static List<String> merge(Iterable<String> first, Iterable<String> more) {
    final seen = <String>{};
    return [
      for (final name in [...first, ...more].map((name) => name.trim()))
        if (name.isNotEmpty && seen.add(name.toLowerCase())) name,
    ];
  }

  static List<String> _sorted(Object? value) {
    final names = value is List
        ? value.whereType<String>().toList()
        : <String>[];
    return names..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
}
