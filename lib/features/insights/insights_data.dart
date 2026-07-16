import '../../core/utils/date_group.dart';
import '../entries/data/entry_model.dart';

class InsightsData {
  const InsightsData({
    required this.totalEntries,
    required this.entriesThisMonth,
    required this.currentStreak,
    required this.averageMood,
    required this.moodCounts,
    required this.last30DaysMood,
  });

  final int totalEntries;
  final int entriesThisMonth;
  final int currentStreak;

  final double averageMood;

  final Map<int, int> moodCounts;

  final List<double?> last30DaysMood;

  bool get isEmpty => totalEntries == 0;

  factory InsightsData.from(List<Entry> entries, {DateTime? now}) {
    final today = DateGroup.dayOnly(now ?? DateTime.now());

    if (entries.isEmpty) {
      return InsightsData(
        totalEntries: 0,
        entriesThisMonth: 0,
        currentStreak: 0,
        averageMood: 0,
        moodCounts: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        last30DaysMood: List<double?>.filled(30, null),
      );
    }

    final thisMonth = entries
        .where((e) =>
            e.createdAt.year == today.year && e.createdAt.month == today.month)
        .length;

    final moodCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    var moodSum = 0;
    for (final e in entries) {
      moodSum += e.mood;
      moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
    }
    final avg = moodSum / entries.length;

    final daysWithEntries =
        entries.map((e) => DateGroup.dayOnly(e.createdAt)).toSet();

    var streak = 0;
    var cursor = today;
    if (!daysWithEntries.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (daysWithEntries.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final sums = List<int>.filled(30, 0);
    final counts = List<int>.filled(30, 0);
    for (final e in entries) {
      final day = DateGroup.dayOnly(e.createdAt);
      final daysAgo = today.difference(day).inDays;
      if (daysAgo >= 0 && daysAgo < 30) {
        final index = 29 - daysAgo;
        sums[index] += e.mood;
        counts[index] += 1;
      }
    }
    final last30 = List<double?>.generate(
      30,
      (i) => counts[i] == 0 ? null : sums[i] / counts[i],
    );

    return InsightsData(
      totalEntries: entries.length,
      entriesThisMonth: thisMonth,
      currentStreak: streak,
      averageMood: avg,
      moodCounts: moodCounts,
      last30DaysMood: last30,
    );
  }
}
