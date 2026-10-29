/// Search works on the text the app already stores, so nothing like
/// Firestore's old `searchKeywords` prefix lists needs to be saved. Text is
/// normalised the same way on both sides of the comparison:
/// - lower case, with accents removed ("Sauté" matches "saute")
/// - "&" treated as "and" ("Fish & Chips" matches "fish and chips")
/// - punctuation treated as spaces ("mac-and-cheese" matches "mac and cheese")
library;

const Map<String, String> _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae', //
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', //
  'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', //
  'ö': 'o', 'ø': 'o', 'œ': 'oe', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
  'ý': 'y', 'ÿ': 'y', 'ß': 'ss',
};

final RegExp _nonWord = RegExp(r'[^a-z0-9]+');

/// Normalises [text] for searching. See the library comment for the rules.
String normaliseForSearch(String text) {
  final lower = text.toLowerCase().replaceAll('&', ' and ');
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().replaceAll(_nonWord, ' ').trim();
}

/// Whether every word of [query] appears somewhere in [fields].
///
/// Words can be in any order and can be part of a longer word, so
/// "rice veg" matches "Vegetable rice". An empty query matches everything.
bool matchesQuery(String query, Iterable<String> fields) {
  final words = normaliseForSearch(query).split(' ').where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = normaliseForSearch(fields.join(' '));
  return words.every(haystack.contains);
}

/// Splits multi-line text into a list, one trimmed item per non-empty line.
/// Leading bullets or numbers such as "- ", "• " or "2. " are removed.
List<String> splitLines(String text) => text
    .split('\n')
    .map((line) => line.trim().replaceFirst(RegExp(r'^([-*•]|\d+[.)])\s*'), ''))
    .where((line) => line.isNotEmpty)
    .toList();
