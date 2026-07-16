import 'package:intl/intl.dart';

/// Utilities for grouping and labeling entry dates.
class DateGroup {
  DateGroup._();

  /// A date with the time stripped — used as a stable key for "same day".
  static DateTime dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// A friendly header for a day: "Today", "Yesterday", or a formatted date.
  static String header(DateTime day, {DateTime? now}) {
    final today = dayOnly(now ?? DateTime.now());
    final target = dayOnly(day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    // Same year: "Mon, 12 Jul". Different year: include the year.
    final pattern = target.year == today.year ? 'EEE, d MMM' : 'EEE, d MMM yyyy';
    return DateFormat(pattern).format(target);
  }

  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);
}
