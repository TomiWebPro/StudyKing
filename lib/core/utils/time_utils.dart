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

String formatDuration(Duration duration, {bool showDays = false, AppLocalizations? l10n}) {
  if (duration.isNegative) return formatDuration(-duration, showDays: showDays, l10n: l10n);
  if (showDays) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (days > 0) {
      return '${_durationPart(days, l10n, _getDurationDays, 'd')} ${_durationPart(hours, l10n, _getDurationHours, 'h')} ${_durationPart(minutes, l10n, _getDurationMinutes, 'm')} ${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
    } else if (hours > 0) {
      return '${_durationPart(hours, l10n, _getDurationHours, 'h')} ${_durationPart(minutes, l10n, _getDurationMinutes, 'm')} ${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
    } else if (minutes > 0) {
      return '${_durationPart(minutes, l10n, _getDurationMinutes, 'm')} ${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
    } else {
      return _durationPart(seconds, l10n, _getDurationSeconds, 's');
    }
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${_durationPart(hours, l10n, _getDurationHours, 'h')} ${_durationPart(minutes, l10n, _getDurationMinutes, 'm')} ${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
  } else if (minutes > 0) {
    return '${_durationPart(minutes, l10n, _getDurationMinutes, 'm')} ${_durationPart(seconds, l10n, _getDurationSeconds, 's')}';
  } else {
    return _durationPart(seconds, l10n, _getDurationSeconds, 's');
  }
}

String _durationPart(int count, AppLocalizations? l10n, String Function(int, AppLocalizations) localized, String fallback) {
  if (l10n != null) return localized(count, l10n);
  return '$count$fallback';
}

String formatDate(DateTime? date, {AppLocalizations? l10n}) {
  final unknown = l10n?.unknown ?? 'Unknown';
  if (date == null) return unknown;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessionDate = DateTime(date.year, date.month, date.day);
  if (sessionDate.isSameDay(today)) {
    return l10n?.today ?? 'Today';
  }
  final diff = today.difference(sessionDate);
  if (diff == const Duration(days: 1)) {
    return l10n?.yesterday ?? 'Yesterday';
  }
  final l10nLocale = l10n != null ? l10n.localeName : 'en';
  return DateFormat.yMd(l10nLocale).format(date);
}

String formatDurationFromContext(BuildContext context, Duration duration, {bool showDays = false}) {
  final l10n = AppLocalizations.of(context);
  return formatDuration(duration, showDays: showDays, l10n: l10n);
}

String formatDateFromContext(BuildContext context, DateTime? date) {
  final l10n = AppLocalizations.of(context);
  return formatDate(date, l10n: l10n);
}

extension DateTimeX on DateTime {
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}