import 'dart:collection';
import 'package:table_calendar/table_calendar.dart';
import 'package:yummealprep/models/meal_planner_item_model.dart';

final currentDate = DateTime.now();
final firstCalendarDate =
    DateTime(currentDate.year, currentDate.month - 3, currentDate.day);
final lastCalendarDate =
    DateTime(currentDate.year, currentDate.month + 3, currentDate.day);
// final meals = MealItemModel.getMeals();

/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
final kMealItems = LinkedHashMap<DateTime, List<MealPlannerItemModel>>(
  equals: isSameDay,
  hashCode: getHashCode,
);

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}
