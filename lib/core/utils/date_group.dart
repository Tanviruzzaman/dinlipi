import 'package:intl/intl.dart';

class DateGroup {
  DateGroup._();

  static DateTime dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String header(DateTime day, {DateTime? now}) {
    final today = dayOnly(now ?? DateTime.now());
    final target = dayOnly(day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    final pattern =
        target.year == today.year ? 'EEE, d MMM' : 'EEE, d MMM yyyy';
    return DateFormat(pattern).format(target);
  }

  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);
}
