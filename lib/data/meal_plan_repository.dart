import 'package:sembast/sembast.dart';

import 'package:yummealprep/data/app_database.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/planned_meal.dart';
import 'package:yummealprep/utils/dates.dart';
import 'package:yummealprep/utils/ids.dart';

/// Which meals are planned for which days.
class MealPlanRepository {
  MealPlanRepository(this.database);

  final AppDatabase database;

  Database get _db => database.db;
  RecordStore get _store => AppDatabase.mealPlan;

  /// Every planned meal, ordered by day and then by slot.
  Stream<List<PlannedMeal>> watchAll() =>
      _store.query().onSnapshots(_db).map(_toEntries);

  Future<List<PlannedMeal>> getAll() async =>
      _toEntries(await _store.find(_db));

  /// Plans [mealId] in [slot] on [date] and returns the new entry. A day can
  /// hold any number of meals, including the same meal more than once.
  Future<PlannedMeal> add({
    required String mealId,
    required DateTime date,
    required MealType slot,
  }) async {
    final entry = PlannedMeal(
      id: newId(),
      mealId: mealId,
      date: dateOnly(date),
      slot: slot,
    );
    await _store.record(entry.id).put(_db, entry.toMap());
    return entry;
  }

  Future<void> remove(String id) => _store.record(id).delete(_db);

  List<PlannedMeal> _toEntries(
    List<RecordSnapshot<String, Map<String, Object?>>> snapshots,
  ) =>
      snapshots
          .map((snapshot) => PlannedMeal.fromMap(snapshot.key, snapshot.value))
          .toList()
        ..sort(_byDayThenSlot);

  static int _byDayThenSlot(PlannedMeal a, PlannedMeal b) {
    final byDay = a.date.compareTo(b.date);
    return byDay != 0 ? byDay : a.slot.index.compareTo(b.slot.index);
  }
}

/// Groups [entries] by day, for the calendar's markers and day list.
Map<DateTime, List<PlannedMeal>> groupByDay(Iterable<PlannedMeal> entries) {
  final days = <DateTime, List<PlannedMeal>>{};
  for (final entry in entries) {
    (days[entry.date] ??= []).add(entry);
  }
  return days;
}
