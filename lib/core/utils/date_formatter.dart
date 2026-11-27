import 'package:intl/intl.dart';

/// Date and time formatting helpers. The optional `now` parameters exist so
/// the logic can be tested deterministically.
abstract final class DateFormatter {
  /// Short timestamp for conversation lists: time today, "Yesterday",
  /// weekday within the last week, otherwise "5 Oct".
  static String listTimestamp(DateTime dateTime, {DateTime? now}) {
    final local = dateTime.toLocal();
    final days = _dayDifference(now ?? DateTime.now(), local);
    if (days <= 0) return DateFormat.jm().format(local);
    if (days == 1) return 'Yesterday';
    if (days < 7) return DateFormat.E().format(local);
    return DateFormat('d MMM').format(local);
  }

  /// Time shown inside a message bubble.
  static String messageTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime.toLocal());
  }

  /// Separator label between days in a chat: "Today", "Yesterday" or a date.
  static String dayLabel(DateTime dateTime, {DateTime? now}) {
    final local = dateTime.toLocal();
    final days = _dayDifference(now ?? DateTime.now(), local);
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return DateFormat.yMMMd().format(local);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final first = a.toLocal();
    final second = b.toLocal();
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // Compares calendar days in UTC so daylight-saving shifts never skew the
  // result.
  static int _dayDifference(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return a.difference(b).inDays;
  }
}
