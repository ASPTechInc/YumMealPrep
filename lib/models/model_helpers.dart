/// Helpers for reading stored maps. Records can come from an older version
/// of the app or from an edited backup, so missing or mistyped values fall
/// back to defaults instead of throwing.
library;

String readString(Object? value) => value is String ? value : '';

String? readOptionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

bool readBool(Object? value) => value is bool && value;

int? readInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.round(),
  final String text => int.tryParse(text),
  _ => null,
};

List<String> readStrings(Object? value) => value is Iterable
    ? value.whereType<String>().where((s) => s.trim().isNotEmpty).toList()
    : const [];

DateTime? readDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
