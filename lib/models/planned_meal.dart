import 'package:flutter/foundation.dart';

import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/model_helpers.dart';
import 'package:yummealprep/utils/dates.dart';

/// A meal placed in a slot (breakfast, lunch and so on) on a given day.
///
/// The entry points at the meal by id rather than copying it, so edits to
/// the meal show up in the planner and the same meal can be planned on as
/// many days as you like.
@immutable
class PlannedMeal {
  const PlannedMeal({
    required this.id,
    required this.mealId,
    required this.date,
    required this.slot,
  });

  factory PlannedMeal.fromMap(String id, Map<String, Object?> map) =>
      PlannedMeal(
        id: id,
        mealId: readString(map['mealId']),
        // An unreadable date falls back to 1970, so it never shows up in
        // the planner rather than breaking it.
        date: dateOnly(readDate(map['day']) ?? DateTime(1970)),
        slot: MealType.parse(map['slot']),
      );

  final String id;
  final String mealId;

  /// The planned day, at midnight.
  final DateTime date;
  final MealType slot;

  Map<String, Object?> toMap() => {
    'mealId': mealId,
    'day': dayKey(date),
    'slot': slot.name,
  };

  @override
  bool operator ==(Object other) =>
      other is PlannedMeal &&
      other.id == id &&
      other.mealId == mealId &&
      other.date == date &&
      other.slot == slot;

  @override
  int get hashCode => Object.hash(id, mealId, date, slot);
}
