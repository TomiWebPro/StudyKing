import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  group('formatDuration', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('formats zero duration', () {
      expect(formatDuration(Duration.zero), '0s');
    });

    test('formats seconds only', () {
      expect(formatDuration(const Duration(seconds: 30)), '30s');
    });

    test('formats single second', () {
      expect(formatDuration(const Duration(seconds: 1)), '1s');
    });

    test('formats multiple seconds', () {
      expect(formatDuration(const Duration(seconds: 45)), '45s');
    });

    test('formats minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 5, seconds: 30)), '5m 30s');
    });

    test('formats single minute', () {
      expect(formatDuration(const Duration(minutes: 1)), '1m 0s');
    });

    test('formats multiple minutes', () {
      expect(formatDuration(const Duration(minutes: 30)), '30m 0s');
    });

    test('formats hours minutes and seconds', () {
      expect(
          formatDuration(const Duration(hours: 1, minutes: 30, seconds: 45), l10n: l10n),
          '1h 30m 45s');
    });

    test('formats single hour', () {
      expect(formatDuration(const Duration(hours: 1), l10n: l10n), '1h 0m 0s');
    });

    test('formats multiple hours', () {
      expect(formatDuration(const Duration(hours: 3, minutes: 15), l10n: l10n), '3h 15m 0s');
    });

    test('formats negative duration as positive', () {
      expect(formatDuration(const Duration(hours: -2), l10n: l10n), '2h 0m 0s');
    });

    group('showDays = true', () {
      test('formats days hours minutes seconds', () {
        expect(
            formatDuration(
              const Duration(days: 2, hours: 3, minutes: 30, seconds: 15),
              showDays: true,
              l10n: l10n,
            ),
            '2d 3h 30m 15s');
      });

      test('formats single day', () {
        expect(
            formatDuration(const Duration(days: 1, hours: 0), showDays: true, l10n: l10n),
            '1d 0h 0m 0s');
      });

      test('formats days hours minutes without seconds', () {
        expect(
            formatDuration(
              const Duration(days: 1, hours: 2, minutes: 30),
              showDays: true,
              l10n: l10n,
            ),
            '1d 2h 30m 0s');
      });

      test('formats without days when less than a day', () {
        expect(
            formatDuration(
              const Duration(hours: 5, minutes: 30, seconds: 15),
              showDays: true,
              l10n: l10n,
            ),
            '5h 30m 15s');
      });
    });
  });

  group('formatDate', () {
    setUpAll(() async {
      await initializeDateFormatting('en');
    });

    test('returns unknown for null date', () {
      expect(formatDate(null), 'Unknown');
    });

    test('returns Today for current date', () {
      final now = DateTime.now();
      expect(formatDate(now), 'Today');
    });

    test('returns Yesterday for previous day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(formatDate(yesterday), 'Yesterday');
    });

    test('returns formatted date for older dates', () {
      final date = DateTime(2025, 6, 15);
      expect(formatDate(date), '6/15/2025');
    });

    test('returns localized Today when l10n provided', () {
      final now = DateTime.now();
      final l10n = AppLocalizationsEn();
      expect(formatDate(now, l10n: l10n), l10n.today);
    });

    test('returns localized Yesterday when l10n provided', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final l10n = AppLocalizationsEn();
      expect(formatDate(yesterday, l10n: l10n), l10n.yesterday);
    });

    test('returns Unknown for null date with l10n', () {
      final l10n = AppLocalizationsEn();
      expect(formatDate(null, l10n: l10n), l10n.unknown);
    });

    test('returns formatted date for future date (tomorrow)', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(formatDate(tomorrow), isNot('Today'));
      expect(formatDate(tomorrow), isNot('Yesterday'));
      expect(formatDate(tomorrow), isNot('Unknown'));
    });

    test('returns formatted date for future date (next week)', () {
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      expect(formatDate(nextWeek), isNot('Today'));
      expect(formatDate(nextWeek), isNot('Yesterday'));
    });

    test('returns formatted date for future date (next year)', () {
      final nextYear = DateTime.now().add(const Duration(days: 365));
      final formatted = formatDate(nextYear);
      expect(formatted, contains('${nextYear.year}'));
    });

    test('returns formatted date for future date with l10n', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final l10n = AppLocalizationsEn();
      final formatted = formatDate(tomorrow, l10n: l10n);
      expect(formatted, isNot(l10n.today));
      expect(formatted, isNot(l10n.yesterday));
      expect(formatted, isNot(l10n.unknown));
    });

  });


  group('DateTimeX.isSameDay', () {
    test('returns true for same day', () {
      final date1 = DateTime(2026, 1, 15, 10, 30);
      final date2 = DateTime(2026, 1, 15, 22, 45);
      expect(date1.isSameDay(date2), isTrue);
    });

    test('returns false for different days same month', () {
      final date1 = DateTime(2026, 1, 15);
      final date2 = DateTime(2026, 1, 20);
      expect(date1.isSameDay(date2), isFalse);
    });

    test('returns false for different months', () {
      final date1 = DateTime(2026, 1, 15);
      final date2 = DateTime(2026, 2, 15);
      expect(date1.isSameDay(date2), isFalse);
    });

    test('returns false for different years', () {
      final date1 = DateTime(2025, 6, 15);
      final date2 = DateTime(2026, 6, 15);
      expect(date1.isSameDay(date2), isFalse);
    });

    test('returns true for same date different times', () {
      final date1 = DateTime(2026, 3, 10, 0, 0, 0);
      final date2 = DateTime(2026, 3, 10, 23, 59, 59);
      expect(date1.isSameDay(date2), isTrue);
    });

    test('returns true for UTC and local same day', () {
      final utc = DateTime.utc(2026, 6, 15, 12, 0, 0);
      final local = DateTime(2026, 6, 15, 8, 0, 0);
      expect(utc.isSameDay(local), isTrue);
    });

    test('returns false for UTC midnight crossing next day local', () {
      final utcLate = DateTime.utc(2026, 1, 15, 23, 30, 0);
      final local = DateTime(2026, 1, 16, 2, 0, 0);
      expect(utcLate.isSameDay(local), isFalse);
    });

    test('returns true for same UTC date regardless of time', () {
      final date1 = DateTime.utc(2026, 12, 25, 0, 0, 0);
      final date2 = DateTime.utc(2026, 12, 25, 23, 59, 59);
      expect(date1.isSameDay(date2), isTrue);
    });
  });
}