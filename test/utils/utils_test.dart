import 'package:flutter_test/flutter_test.dart';

import 'package:yummealprep/utils/dates.dart';
import 'package:yummealprep/utils/ids.dart';
import 'package:yummealprep/utils/search.dart';
import 'package:yummealprep/utils/ui.dart';

void main() {
  group('matchesQuery', () {
    const fields = ['Vegetable Rice', 'Turmeric rice with mixed vegetables'];

    test('matches everything when the query is empty', () {
      expect(matchesQuery('', fields), isTrue);
      expect(matchesQuery('   ', fields), isTrue);
    });

    test('ignores case and finds words anywhere', () {
      expect(matchesQuery('RICE', fields), isTrue);
      expect(matchesQuery('table', fields), isTrue);
    });

    test('ignores accents, punctuation and "&" versus "and"', () {
      expect(matchesQuery('saute', ['Sauté the onions']), isTrue);
      expect(matchesQuery('fish and chips', ['Fish & Chips']), isTrue);
      expect(matchesQuery('mac and cheese', ['Mac-and-cheese']), isTrue);
      expect(matchesQuery('meatballs', ['Spaghetti & Meatballs']), isTrue);
    });

    test('needs every word, in any order', () {
      expect(matchesQuery('rice veg', fields), isTrue);
      expect(matchesQuery('rice chicken', fields), isFalse);
    });
  });

  group('splitLines', () {
    test('keeps one trimmed item per non-empty line', () {
      expect(splitLines(' 2 cups rice \n\n1 tsp salt\n'), [
        '2 cups rice',
        '1 tsp salt',
      ]);
    });

    test('removes bullets and step numbers typed by hand', () {
      expect(splitLines('- Wash the rice\n• Drain it\n3. Boil\n4) Serve'), [
        'Wash the rice',
        'Drain it',
        'Boil',
        'Serve',
      ]);
    });

    test('keeps the order of the lines', () {
      expect(splitLines('Zest\nApple\nMix'), ['Zest', 'Apple', 'Mix']);
    });
  });

  group('dates', () {
    test('dayKey pads month and day', () {
      expect(dayKey(DateTime(2026, 3, 7, 18, 30)), '2026-03-07');
    });

    test('lastPlannableDay is two years ahead, to the day', () {
      expect(lastPlannableDay(DateTime(2026, 10, 28)), DateTime(2028, 10, 28));
    });

    test('isTodayOrLater compares whole days', () {
      final now = DateTime(2026, 10, 28, 23, 59);
      expect(isTodayOrLater(DateTime(2026, 10, 28), now: now), isTrue);
      expect(isTodayOrLater(DateTime(2026, 11, 2), now: now), isTrue);
      expect(isTodayOrLater(DateTime(2026, 10, 27, 23), now: now), isFalse);
    });
  });

  test('formatMinutes', () {
    expect(formatMinutes(5), '5 min');
    expect(formatMinutes(60), '1 hr');
    expect(formatMinutes(95), '1 hr 35 min');
  });

  test('newId gives unique ids', () {
    final ids = {for (var i = 0; i < 1000; i++) newId()};
    expect(ids, hasLength(1000));
  });
}
