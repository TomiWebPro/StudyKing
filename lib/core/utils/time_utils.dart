import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

String _getDurationDays(int count, AppLocalizations l10n) {
  return l10n.durationDays(count);
}

String _getDurationHours(int count, AppLocalizations l10n) {
  return l10n.durationHours(count);
}

String _getDurationMinutes(int count, AppLocalizations l10n) {
  return l10n.durationMinutes(count);
}

String _getDurationSeconds(int count, AppLocalizations l10n) {
  return l10n.durationSeconds(count);
}

String _getDurationSeparator(AppLocalizations? l10n) {
  return l10n?.durationSeparator ?? ' ';
}

String formatDuration(Duration duration, {bool showDays = false, AppLocalizations? l10n}) {
  if (duration.isNegative) return formatDuration(-duration, showDays: showDays, l10n: l10n);
  final sep = _getDurationSeparator(l10n);
  if (showDays) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (days > 0) {
      return '${_durationPart(days, l10n, _getDurationDays, 'd')}$sep${_durationPart(hours, l10n, _getDurationHours, 'h')}$sep${_durationPart(minutes, l10n, _getDurationMinutes, 'm')}$sep${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
    } else if (hours > 0) {
      return '${_durationPart(hours, l10n, _getDurationHours, 'h')}$sep${_durationPart(minutes, l10n, _getDurationMinutes, 'm')}$sep${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
    } else if (minutes > 0) {
      return '${_durationPart(minutes, l10n, _getDurationMinutes, 'm')}$sep${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
    } else {
      return _durationPart(seconds, l10n, _getDurationSeconds, 's');
    }
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${_durationPart(hours, l10n, _getDurationHours, 'h')}$sep${_durationPart(minutes, l10n, _getDurationMinutes, 'm')}$sep${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
  } else if (minutes > 0) {
    return '${_durationPart(minutes, l10n, _getDurationMinutes, 'm')}$sep${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
  } else {
    return _durationPart(seconds, l10n, _getDurationSeconds, 's');
  }
}

String _durationPart(int count, AppLocalizations? l10n, String Function(int, AppLocalizations) localized, String fallback) {
  // covariant: l10n is always non-null in production
  if (l10n != null) return localized(count, l10n);
  return '$count$fallback';
}

String formatDate(DateTime? date, {AppLocalizations? l10n, DateTime? now}) {
  // covariant: l10n is always non-null in production (AppLocalizations.of(context) is called upstream)
  final unknown = l10n?.unknown ?? 'Unknown';
  if (date == null) return unknown;
  final today = (now ?? DateTime.now()).dateOnly;
  final sessionDate = date.dateOnly;
  if (sessionDate.isSameDay(today)) {
    return l10n?.today ?? 'Today';
  }
  // Compare calendar days, not elapsed time: on DST-transition days
  // consecutive local midnights are 23h/25h apart, so difference()
  // never equals exactly Duration(days: 1) and an elapsed-time check
  // would miss a session that is exactly one calendar day old.
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  if (sessionDate.isSameDay(yesterday)) {
    return l10n?.yesterday ?? 'Yesterday';
  }
  final l10nLocale = l10n != null ? l10n.localeName : 'en';
  return DateFormat.yMd(l10nLocale).format(date);
}

String formatDurationFromContext(BuildContext context, Duration duration, {bool showDays = false}) {
  final l10n = AppLocalizations.of(context);
  return formatDuration(duration, showDays: showDays, l10n: l10n);
}

String formatTimer(Duration duration, {AppLocalizations? l10n}) {
  if (duration.isNegative) return formatTimer(-duration, l10n: l10n);
  final sep = _getDurationSeparator(l10n);
  final localeName = l10n?.localeName ?? 'en';
  final h = duration.inHours;
  final m = duration.inMinutes.remainder(60);
  final s = duration.inSeconds.remainder(60);
  final twoDigits = NumberFormat('00', localeName);
  if (h > 0) {
    return '${twoDigits.format(h)}$sep${twoDigits.format(m)}$sep${twoDigits.format(s)}';
  }
  return '${twoDigits.format(m)}$sep${twoDigits.format(s)}';
}

String formatTimerFromContext(BuildContext context, Duration duration) {
  final l10n = AppLocalizations.of(context);
  return formatTimer(duration, l10n: l10n);
}

String formatDateFromContext(BuildContext context, DateTime? date) {
  final l10n = AppLocalizations.of(context);
  return formatDate(date, l10n: l10n);
}

extension DateTimeX on DateTime {
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  DateTime get dateOnly => DateTime(year, month, day);
}