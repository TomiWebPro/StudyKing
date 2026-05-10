import 'package:intl/intl.dart';

/// Formats a [Duration] as a human-readable string (e.g. "1h 2m 3s").
/// Negative durations are returned as their absolute value.
/// If [showDays] is true, durations >= 24 hours are shown with a day component
/// (e.g. "1d 2h 3m 4s").
String formatDuration(Duration duration, {bool showDays = false}) {
  if (duration.isNegative) return formatDuration(-duration, showDays: showDays);
  if (showDays) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${seconds}s';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}m ${seconds}s';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

/// Formats a [DateTime] as a human-readable relative date string.
/// Returns "Today", "Yesterday", or a locale-aware formatted date.
/// If [date] is null, returns "Unknown".
/// Comparisons use normalized local dates for timezone safety.
String formatDate(DateTime? date) {
  if (date == null) return 'Unknown';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessionDate = DateTime(date.year, date.month, date.day);
  if (sessionDate.isSameDay(today)) {
    return 'Today';
  }
  final diff = today.difference(sessionDate);
  if (diff == const Duration(days: 1)) {
    return 'Yesterday';
  }
  return DateFormat.yMd().format(date);
}

/// Extension on [DateTime] providing convenient comparison methods.
extension DateTimeX on DateTime {
  /// Returns true if this [DateTime] falls on the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
