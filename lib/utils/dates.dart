/// Day-level date helpers. The planner works in whole days, so times and
/// time zones are dropped before anything is stored or compared.
library;

/// Returns midnight (local time) of [date].
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// A sortable `yyyy-MM-dd` key for [date], used as the stored plan date.
String dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

/// The last day meals can be planned for, two years from [today].
DateTime lastPlannableDay(DateTime today) =>
    DateTime(today.year + 2, today.month, today.day);

/// Whether [date] is today or later.
bool isTodayOrLater(DateTime date, {DateTime? now}) =>
    !dateOnly(date).isBefore(dateOnly(now ?? DateTime.now()));
