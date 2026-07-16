import 'package:flutter_test/flutter_test.dart';

import 'package:journal_app/core/utils/date_group.dart';
import 'package:journal_app/core/utils/mood.dart';

void main() {
  group('Mood', () {
    test('has 5 values with labels and colors', () {
      expect(Mood.values.length, 5);
      for (final m in Mood.values) {
        expect(Mood.label(m).isNotEmpty, true);

        Mood.color(m);
        Mood.icon(m);
      }
    });
  });

  group('DateGroup', () {
    final now = DateTime(2026, 7, 13, 10, 0);

    test('labels today and yesterday', () {
      expect(DateGroup.header(now, now: now), 'Today');
      expect(
        DateGroup.header(now.subtract(const Duration(days: 1)), now: now),
        'Yesterday',
      );
    });

    test('isSameDay ignores time', () {
      expect(
        DateGroup.isSameDay(
          DateTime(2026, 7, 13, 1),
          DateTime(2026, 7, 13, 23),
        ),
        true,
      );
      expect(
        DateGroup.isSameDay(DateTime(2026, 7, 13), DateTime(2026, 7, 14)),
        false,
      );
    });
  });
}
