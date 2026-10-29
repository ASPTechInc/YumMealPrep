import 'dart:math';

final Random _random = Random();

/// Creates a unique, URL-safe record id such as `m4x2k9q1-3fz8a0`.
///
/// The time part keeps ids roughly in creation order and the random part
/// keeps them unique when several records are created in the same moment.
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  // 0x7FFFFFFF rather than 1 << 32, which is 0 when compiled to JavaScript.
  final random = _random.nextInt(0x7FFFFFFF).toRadixString(36).padLeft(6, '0');
  return '$time-$random';
}
