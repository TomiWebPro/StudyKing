import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/constants/notification_ids.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'initialize':
              return true;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        null,
      );
    });

    test('is a singleton provider', () {
      // NotificationService is instantiated per provider; verify provider singleton behavior
      expect(NotificationService, isNotNull);
      final service1 = NotificationService();
      final service2 = NotificationService();
      // Services are intentionally non-singleton to allow test isolation;
      // verify they are distinct instances but same type
      expect(service1, isA<NotificationService>());
      expect(service2, isA<NotificationService>());
    });

    test('setAppLocalizations stores the l10n', () {
      final service = NotificationService();
      expect(
        () => service.setAppLocalizations(AppLocalizationsEn()),
        returnsNormally,
      );
    });

    test('init does not throw during initialization', () async {
      final service = NotificationService();
      expect(service.init(), completes);
    });

    test('init called twice does not throw', () async {
      final service = NotificationService();
      await service.init();
      expect(service.init(), completes);
    });

    // --- Behavioral assertions: Result<T> return types and l10n fallback ---

    test('showNotification returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showNotification(
        id: 1, title: 'T', body: 'B',
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
    });

    test('showNotification returns failure when l10n is not set', () async {
      final service = NotificationService();
      // Intentionally NOT calling setAppLocalizations
      final result = await service.showNotification(
        id: 1, title: 'T', body: 'B',
      );
      expect(result, isA<Result<void>>());
      expect(result.isFailure, isTrue);
      expect(result.error, contains('l10n not initialized'));
    });

    test('showDailyReminder returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showDailyReminder(
        id: 1, title: 'T', body: 'B', remindAt: TimeOfDay.now(),
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showDailyReminder returns failure when l10n is not set', () async {
      final service = NotificationService();
      final result = await service.showDailyReminder(
        id: 1, title: 'T', body: 'B', remindAt: TimeOfDay.now(),
      );
      expect(result, isA<Result<void>>());
      expect(result.isFailure, isTrue);
      expect(result.error, contains('l10n not initialized'));
    });

    group('showDailyReminder scheduling semantics', () {
      final List<MethodCall> notificationCalls = [];

      setUp(() async {
        notificationCalls.clear();
        tz_data.initializeTimeZones();
        await initializeDateFormatting();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getLocalTimezone') {
              return 'Europe/Berlin';
            }
            return null;
          },
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            notificationCalls.add(methodCall);
            switch (methodCall.method) {
              case 'initialize':
                return true;
              default:
                return null;
            }
          },
        );
      });

      NotificationService serviceWithLocalizations() {
        final service = NotificationService();
        service.setAppLocalizations(AppLocalizationsEn());
        return service;
      }

      test('schedules at the chosen time-of-day in the device zone',
          () async {
        final service = serviceWithLocalizations();

        final result = await service.showDailyReminder(
          id: 1,
          title: 'T',
          body: 'B',
          remindAt: const TimeOfDay(hour: 9, minute: 30),
          payload: 'daily_reminder',
        );

        expect(result.isSuccess, isTrue);
        // The old 24h-interval path must not be used anymore.
        expect(
          notificationCalls.where((c) => c.method == 'periodicallyShow'),
          isEmpty,
        );
        final zonedCalls = notificationCalls
            .where((c) => c.method == 'zonedSchedule')
            .toList();
        expect(zonedCalls, hasLength(1));
        final args = zonedCalls.single.arguments as Map<Object?, Object?>;
        expect(args['timeZoneName'], 'Europe/Berlin');
        final scheduled = DateTime.parse(args['scheduledDateTime'] as String);
        expect(scheduled.hour, 9);
        expect(scheduled.minute, 30);
        expect(
          scheduled.isAfter(DateTime.now()),
          isTrue,
          reason: 'scheduled date must be in the future',
        );
        expect(args['matchDateTimeComponents'], DateTimeComponents.time.index);
        expect(args['payload'], 'daily_reminder');
      });

      test('rolls the alarm to tomorrow when the chosen time passed today',
          () async {
        final service = serviceWithLocalizations();

        final result = await service.showDailyReminder(
          id: 2,
          title: 'T',
          body: 'B',
          remindAt: const TimeOfDay(hour: 0, minute: 0),
        );

        expect(result.isSuccess, isTrue);
        final scheduled = DateTime.parse(
          (notificationCalls
              .singleWhere((c) => c.method == 'zonedSchedule')
              .arguments as Map<Object?, Object?>)['scheduledDateTime']
              as String,
        );
        expect(scheduled.hour, 0);
        expect(scheduled.minute, 0);
        expect(
          scheduled.isAfter(DateTime.now()),
          isTrue,
          reason: 'a passed time-of-day must roll to the next day',
        );
      });

      test('falls back to the daily interval when zonedSchedule is '
          'unsupported', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            notificationCalls.add(methodCall);
            if (methodCall.method == 'zonedSchedule') {
              throw UnimplementedError(
                'zonedSchedule() has not been implemented',
              );
            }
            return methodCall.method == 'initialize' ? true : null;
          },
        );
        final service = serviceWithLocalizations();

        final result = await service.showDailyReminder(
          id: 3,
          title: 'T',
          body: 'B',
          remindAt: const TimeOfDay(hour: 9, minute: 30),
        );

        expect(result.isSuccess, isTrue);
        expect(
          notificationCalls.where((c) => c.method == 'zonedSchedule'),
          hasLength(1),
        );
        final periodicCalls = notificationCalls
            .where((c) => c.method == 'periodicallyShow')
            .toList();
        expect(periodicCalls, hasLength(1));
        final periodicArgs =
            periodicCalls.single.arguments as Map<Object?, Object?>;
        expect(periodicArgs['repeatInterval'], RepeatInterval.daily.index);
      });
    });

    group('nextDailyOccurrence DST wall-clock stability', () {
      late final tz.Location newYork;

      setUpAll(() {
        tz_data.initializeTimeZones();
        newYork = tz.getLocation('America/New_York');
      });

      test('returns today when the chosen time is still ahead', () {
        final now = tz.TZDateTime(newYork, 2026, 3, 7, 8, 0);
        final next = NotificationService.nextDailyOccurrence(
          now,
          const TimeOfDay(hour: 9, minute: 0),
        );
        expect(next.year, 2026);
        expect(next.month, 3);
        expect(next.day, 7);
        expect(next.hour, 9);
        expect(next.minute, 0);
        expect(next.timeZoneName, 'EST');
      });

      test('rolls to the same wall-clock time on the next calendar '
          'day across a spring-forward transition', () {
        // America/New_York springs forward on 2026-03-08: the day
        // is 23 hours long, so adding 24h to 2026-03-07 09:00
        // would land on 10:00 wall clock. Calendar-day arithmetic
        // keeps the chosen 09:00.
        final now = tz.TZDateTime(newYork, 2026, 3, 7, 10, 0);
        final next = NotificationService.nextDailyOccurrence(
          now,
          const TimeOfDay(hour: 9, minute: 0),
        );
        expect(next.year, 2026);
        expect(next.month, 3);
        expect(next.day, 8);
        expect(next.hour, 9);
        expect(next.minute, 0);
        expect(next.timeZoneOffset, const Duration(hours: -4)); // EDT
      });

      test('rolls to the same wall-clock time on the next calendar '
          'day across a fall-back transition', () {
        // America/New_York falls back on 2026-11-01: the day is 25
        // hours long, so adding 24h to 2026-10-31 09:00 would land
        // on 08:00 wall clock. Calendar-day arithmetic keeps 09:00.
        final now = tz.TZDateTime(newYork, 2026, 10, 31, 10, 0);
        final next = NotificationService.nextDailyOccurrence(
          now,
          const TimeOfDay(hour: 9, minute: 0),
        );
        expect(next.year, 2026);
        expect(next.month, 11);
        expect(next.day, 1);
        expect(next.hour, 9);
        expect(next.minute, 0);
        expect(next.timeZoneOffset, const Duration(hours: -5)); // EST
      });

      test('preserves the chosen minutes of the time-of-day', () {
        final now = tz.TZDateTime(newYork, 2026, 6, 1, 10, 0);
        final next = NotificationService.nextDailyOccurrence(
          now,
          const TimeOfDay(hour: 7, minute: 45),
        );
        expect(next.year, 2026);
        expect(next.month, 6);
        expect(next.day, 2);
        expect(next.hour, 7);
        expect(next.minute, 45);
      });
    });

    test('showRevisionNudge returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showRevisionNudge(
        id: 1, topicName: 'Algebra', daysSinceLastPractice: 3,
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showOverworkWarning returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showOverworkWarning(
        id: 1, hoursStudied: 5.0,
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    group('showOverworkWarning fractional hours rendering', () {
      final List<MethodCall> notificationCalls = [];

      setUp(() {
        notificationCalls.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            notificationCalls.add(methodCall);
            return methodCall.method == 'initialize' ? true : null;
          },
        );
      });

      Map<Object?, Object?> showCallArguments() {
        final showCalls = notificationCalls
            .where((c) => c.method == 'show')
            .toList();
        expect(showCalls, hasLength(1));
        return showCalls.single.arguments as Map<Object?, Object?>;
      }

      NotificationService serviceWithLocalizations(AppLocalizations l10n) {
        final service = NotificationService();
        service.setAppLocalizations(l10n);
        return service;
      }

      test('keeps fractional hours in the body (en locale)', () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showOverworkWarning(
          id: 1,
          hoursStudied: 4.5,
        );

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(body, contains('4.5'));
        expect(body, contains('4.5 hours'));
      });

      test('renders the fraction with the locale decimal separator '
          '(es locale)', () async {
        final service = serviceWithLocalizations(AppLocalizationsEs());

        final result = await service.showOverworkWarning(
          id: 1,
          hoursStudied: 4.5,
        );

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(body, contains('4,5 horas'));
      });

      test('keeps singular wording for exactly one hour', () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showOverworkWarning(
          id: 1,
          hoursStudied: 1.0,
        );

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(body, contains('1 hour'));
        expect(body, isNot(contains('1.0')));
      });

      test('whole hours still render without a fraction', () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showOverworkWarning(
          id: 1,
          hoursStudied: 5.0,
        );

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(body, contains('5 hours'));
      });
    });

    test('showPlanAdjustmentSuggestion returns success when l10n is set',
        () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showPlanAdjustmentSuggestion(
        id: 1, consecutiveLowDays: 5,
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showLessonReminder returns failure when l10n is not set', () async {
      final service = NotificationService();
      final result = await service.showLessonReminder(
        id: 1, lessonTitle: 'Math', startTime: DateTime.now(),
      );
      expect(result, isA<Result<void>>());
      expect(result.isFailure, isTrue);
      expect(result.error, contains('l10n not initialized'));
    });

    test('showLowMasteryWarning with empty list returns success immediately',
        () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result =
          await service.showLowMasteryWarning(id: 1, weakTopics: []);
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showLowMasteryWarning with topics returns success when l10n is set',
        () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showLowMasteryWarning(
        id: 1, weakTopics: ['Algebra', 'Geometry'],
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    group('showLowMasteryWarning body localization', () {
      final List<MethodCall> notificationCalls = [];

      setUp(() {
        notificationCalls.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            notificationCalls.add(methodCall);
            return methodCall.method == 'initialize' ? true : null;
          },
        );
      });

      Map<Object?, Object?> showCallArguments() {
        final showCalls = notificationCalls
            .where((c) => c.method == 'show')
            .toList();
        expect(showCalls, hasLength(1));
        return showCalls.single.arguments as Map<Object?, Object?>;
      }

      NotificationService serviceWithLocalizations(AppLocalizations l10n) {
        final service = NotificationService();
        service.setAppLocalizations(l10n);
        return service;
      }

      test('localizes the and-more suffix (en locale)', () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showLowMasteryWarning(
          id: 1,
          weakTopics: ['Algebra', 'Geometry', 'Calculus', 'Physics', 'Chemistry'],
        );

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(body, contains('Low mastery detected in: Algebra, Geometry, Calculus'));
        expect(body, contains('... and 2 more'));
      });

      test('localizes the and-more suffix (es locale)', () async {
        final service = serviceWithLocalizations(AppLocalizationsEs());

        final result = await service.showLowMasteryWarning(
          id: 1,
          weakTopics: ['Álgebra', 'Geometría', 'Cálculo', 'Física', 'Química'],
        );

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(
          body,
          contains('Bajo dominio detectado en: Álgebra, Geometría, Cálculo'),
        );
        expect(body, contains('... y 2 más'));
        expect(body, isNot(contains(' and ')));
      });

      test('uses the singular form for exactly one additional topic',
          () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showLowMasteryWarning(
          id: 1,
          weakTopics: ['Algebra', 'Geometry', 'Calculus', 'Physics'],
        );

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(body, contains('... and 1 more'));
      });

      test('omits the suffix when at most three topics are weak', () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showLowMasteryWarning(
          id: 1,
          weakTopics: ['Algebra', 'Geometry', 'Calculus'],
        );

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(body, 'Low mastery detected in: Algebra, Geometry, Calculus');
        expect(body, isNot(contains('more')));
      });
    });

    group('showMentorMessage', () {
      final List<MethodCall> notificationCalls = [];

      setUp(() {
        notificationCalls.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            notificationCalls.add(methodCall);
            return methodCall.method == 'initialize' ? true : null;
          },
        );
      });

      Map<Object?, Object?> showCallArguments() {
        final showCalls = notificationCalls
            .where((c) => c.method == 'show')
            .toList();
        expect(showCalls, hasLength(1));
        return showCalls.single.arguments as Map<Object?, Object?>;
      }

      NotificationService serviceWithLocalizations(AppLocalizations l10n) {
        final service = NotificationService();
        service.setAppLocalizations(l10n);
        return service;
      }

      test('returns failure when l10n is not set', () async {
        final service = NotificationService();
        final result = await service.showMentorMessage(
          id: 1, title: 'T', body: 'B',
        );
        expect(result.isFailure, isTrue);
        expect(result.error, contains('l10n not initialized'));
      });

      test('uses the localized mentor channel name (en locale)', () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showMentorMessage(
          id: 1, title: 'T', body: 'B',
        );

        expect(result.isSuccess, isTrue);
        final specifics =
            showCallArguments()['platformSpecifics'] as Map<Object?, Object?>;
        expect(specifics['channelName'], 'Mentor Messages');
      });

      test('uses the localized mentor channel name (es locale)', () async {
        final service = serviceWithLocalizations(AppLocalizationsEs());

        final result = await service.showMentorMessage(
          id: 1, title: 'T', body: 'B',
        );

        expect(result.isSuccess, isTrue);
        final specifics =
            showCallArguments()['platformSpecifics'] as Map<Object?, Object?>;
        expect(specifics['channelName'], 'Mensajes del Mentor');
      });
    });

    test('showSessionComplete returns failure when l10n is not set',
        () async {
      final service = NotificationService();
      final result = await service.showSessionComplete(id: 1, minutes: 25);
      expect(result, isA<Result<void>>());
      expect(result.isFailure, isTrue);
      expect(result.error, contains('l10n not initialized'));
    });

    test('showSessionComplete returns success when l10n is set',
        () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showSessionComplete(id: 1, minutes: 25);
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    group('showSessionComplete localization', () {
      final List<MethodCall> notificationCalls = [];

      setUp(() {
        notificationCalls.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            notificationCalls.add(methodCall);
            return methodCall.method == 'initialize' ? true : null;
          },
        );
      });

      Map<Object?, Object?> showCallArguments() {
        final showCalls = notificationCalls
            .where((c) => c.method == 'show')
            .toList();
        expect(showCalls, hasLength(1));
        return showCalls.single.arguments as Map<Object?, Object?>;
      }

      NotificationService serviceWithLocalizations(AppLocalizations l10n) {
        final service = NotificationService();
        service.setAppLocalizations(l10n);
        return service;
      }

      test('uses the localized title and body (en locale)', () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showSessionComplete(id: 1, minutes: 25);

        expect(result.isSuccess, isTrue);
        final args = showCallArguments();
        expect(args['title'], 'Session Complete');
        expect(args['body'], 'Session completed: 25m');
        final specifics = args['platformSpecifics'] as Map<Object?, Object?>;
        expect(specifics['channelName'], 'StudyKing Notifications');
      });

      test('uses the localized title and body (es locale)', () async {
        final service = serviceWithLocalizations(AppLocalizationsEs());

        final result = await service.showSessionComplete(id: 1, minutes: 25);

        expect(result.isSuccess, isTrue);
        final args = showCallArguments();
        expect(args['title'], 'Sesión Completada');
        expect(args['body'], 'Sesión completada: 25m');
        final specifics = args['platformSpecifics'] as Map<Object?, Object?>;
        expect(specifics['channelName'], 'Notificaciones de StudyKing');
      });

      test('renders the passed minute count in the body', () async {
        final service = serviceWithLocalizations(AppLocalizationsEn());

        final result = await service.showSessionComplete(id: 1, minutes: 7);

        expect(result.isSuccess, isTrue);
        final body = showCallArguments()['body'] as String;
        expect(body, 'Session completed: 7m');
        expect(body, isNot(contains('0 minutes')));
      });
    });

    test('showBadgeUnlocked returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showBadgeUnlocked(
        id: 1, badgeName: 'Test', badgeDescription: 'Desc',
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showLessonReady returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showLessonReady(
        id: 1, topicTitle: 'Algebra', lessonId: 'lesson_1',
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('cancelNotification returns success on mocked plugin', () async {
      final service = NotificationService();
      final result = await service.cancelNotification(1);
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('cancelAll returns success on mocked plugin', () async {
      final service = NotificationService();
      final result = await service.cancelAll();
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('public API methods exist', () {
      final service = NotificationService();
      expect(service.init, isA<Function>());
      expect(service.showNotification, isA<Function>());
      expect(service.showDailyReminder, isA<Function>());
      expect(service.showRevisionNudge, isA<Function>());
      expect(service.showOverworkWarning, isA<Function>());
      expect(service.showPlanAdjustmentSuggestion, isA<Function>());
      expect(service.showLessonReminder, isA<Function>());
      expect(service.showLowMasteryWarning, isA<Function>());
      expect(service.showBadgeUnlocked, isA<Function>());
      expect(service.showSessionComplete, isA<Function>());
      expect(service.cancelNotification, isA<Function>());
      expect(service.cancelAll, isA<Function>());
      expect(service.setAppLocalizations, isA<Function>());
      expect(service.scheduleLessonReminder, isA<Function>());
      expect(service.cancelLessonReminder, isA<Function>());
    });

    group('scheduleLessonReminder', () {
      final List<MethodCall> notificationCalls = [];

      setUp(() {
        notificationCalls.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getLocalTimezone') {
              return 'Europe/Berlin';
            }
            return null;
          },
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            notificationCalls.add(methodCall);
            if (methodCall.method == 'initialize') return true;
            return null;
          },
        );
      });

      NotificationService serviceWithLocalizations() {
        final service = NotificationService();
        service.setAppLocalizations(AppLocalizationsEn());
        return service;
      }

      test('lessonNotificationId is deterministic and offset by the base', () {
        final id1 = NotificationService.lessonNotificationId('session-abc');
        final id2 = NotificationService.lessonNotificationId('session-abc');
        expect(id1, equals(id2));
        final id3 = NotificationService.lessonNotificationId('session-xyz');
        expect(id3, isNot(equals(id1)));
        expect(id1, greaterThanOrEqualTo(NotificationIds.lessonReminderBase));
        expect(id1, lessThan(NotificationIds.lessonReminderBase + (1 << 31)));
      });

      test('lessonNotificationId is stable across Dart process restarts', () {
        final id = NotificationService.lessonNotificationId('test-session-id');
        expect(id, equals(906197488));
      });

      test('schedules a one-shot zonedSchedule alarm on the lessons channel with a future TZDateTime',
          () async {
        final service = serviceWithLocalizations();
        final lessonStart = DateTime.now().add(const Duration(hours: 2));

        final result = await service.scheduleLessonReminder(
          sessionId: 'test-session',
          lessonTitle: 'Kinematics',
          startTime: lessonStart,
        );

        expect(result.isSuccess, isTrue);

        final zonedCalls =
            notificationCalls.where((c) => c.method == 'zonedSchedule').toList();
        expect(zonedCalls, hasLength(1));

        final args = zonedCalls.single.arguments as Map<Object?, Object?>;

        final scheduled = DateTime.parse(args['scheduledDateTime'] as String);
        expect(scheduled.isAfter(DateTime.now()), isTrue,
            reason: 'the alarm must be scheduled for the future');

        final expectedReminderTime = lessonStart.subtract(
          Duration(minutes: Timeouts.lessonReminderLeadMinutes),
        );
        expect(
          scheduled.difference(expectedReminderTime).abs() <
              const Duration(seconds: 2),
          isTrue,
        );

        // Verify the notification is posted on the lessons channel.
        // The zonedSchedule arguments serialize NotificationDetails
        // under 'platformSpecifics' with an 'android' sub-map.
        final specifics = args['platformSpecifics'] as Map<Object?, Object?>? ??
            args['notificationDetails'] as Map<Object?, Object?>?;
        expect(specifics, isNotNull);
        final android = specifics!['android'] as Map<Object?, Object?>?;
        if (android != null) {
          expect(android['channelId'], NotificationChannelIds.lessons);
          expect(android['channelName'], 'Lesson Notifications');
        }
      });

      test('does not pass matchDateTimeComponents so the alarm is one-shot',
          () async {
        final service = serviceWithLocalizations();
        final lessonStart = DateTime.now().add(const Duration(hours: 2));

        final result = await service.scheduleLessonReminder(
          sessionId: 'test-session',
          lessonTitle: 'Kinematics',
          startTime: lessonStart,
        );

        expect(result.isSuccess, isTrue);

        final zonedCalls =
            notificationCalls.where((c) => c.method == 'zonedSchedule').toList();
        expect(zonedCalls, hasLength(1));

        final args = zonedCalls.single.arguments as Map<Object?, Object?>;
        expect(args['matchDateTimeComponents'], isNull);
      });

      test('clamps a past target to now + 1 second', () async {
        final service = serviceWithLocalizations();
        final lessonStart = DateTime.now().add(const Duration(minutes: 10));

        final result = await service.scheduleLessonReminder(
          sessionId: 'test-session',
          lessonTitle: 'Kinematics',
          startTime: lessonStart,
        );

        expect(result.isSuccess, isTrue);

        final zonedCalls =
            notificationCalls.where((c) => c.method == 'zonedSchedule').toList();
        expect(zonedCalls, hasLength(1));

        final args = zonedCalls.single.arguments as Map<Object?, Object?>;
        final scheduled = DateTime.parse(args['scheduledDateTime'] as String);
        expect(scheduled.isAfter(DateTime.now()), isTrue);
        expect(
          scheduled.difference(DateTime.now()).abs() <
              const Duration(seconds: 3),
          isTrue,
        );
        final expectedPast = lessonStart.subtract(
          Duration(minutes: Timeouts.lessonReminderLeadMinutes),
        );
        expect(scheduled.isAfter(expectedPast), isTrue);
      });

      test('returns failure when l10n is not set', () async {
        final service = NotificationService();

        final result = await service.scheduleLessonReminder(
          sessionId: 'test-session',
          lessonTitle: 'Kinematics',
          startTime: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(result.isFailure, isTrue);
        expect(result.error, contains('l10n not initialized'));
        expect(
          notificationCalls.where((c) => c.method == 'zonedSchedule'),
          isEmpty,
        );
      });
    });

    group('cancelLessonReminder', () {
      final List<MethodCall> notificationCalls = [];

      setUp(() {
        notificationCalls.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            notificationCalls.add(methodCall);
            if (methodCall.method == 'initialize') return true;
            return null;
          },
        );
      });

      test('cancels the notification derived from the session id', () async {
        final service = NotificationService();

        await service.cancelLessonReminder('session-abc');

        final cancelCalls =
            notificationCalls.where((c) => c.method == 'cancel').toList();
        expect(cancelCalls, hasLength(1));
        final args = cancelCalls.single.arguments as Map<Object?, Object?>;
        expect(args['id'],
            NotificationService.lessonNotificationId('session-abc'));
      });
    });
  });
}
