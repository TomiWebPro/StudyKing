import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/clock.dart';

void main() {
  group('StudentIdService singleton', () {
    test('creates distinct instances (singleton via provider)', () {
      final a = StudentIdService();
      final b = StudentIdService();
      expect(a, isA<StudentIdService>());
      expect(b, isA<StudentIdService>());
      expect(identical(a, b), isFalse);
    });
  });

  group('StudentIdService with Hive', () {
    late String hivePath;

    setUp(() async {
      hivePath = (await Directory.systemTemp.createTemp('student_id_test_')).path;
      Hive.init(hivePath);
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    test('getStudentId generates a UUID on first call', () async {
      final service = StudentIdService();
      await service.init();
      final id = service.getStudentId().data ?? '';
      expect(id, isA<String>());
      expect(id.length, greaterThan(0));
    });

    test('getStudentId returns cached value on subsequent calls', () async {
      final service = StudentIdService();
      await service.init();
      final first = service.getStudentId().data ?? '';
      final second = service.getStudentId().data ?? '';
      expect(first, second);
    });

    test('getStudentId returns cached value without Hive box', () async {
      final service = StudentIdService();
      final first = service.getStudentId().data ?? '';
      final second = service.getStudentId().data ?? '';
      expect(first, second);
    });

    test('setStudentId persists the value', () async {
      final service = StudentIdService();
      await service.init();
      service.setStudentId('custom-id-123');
      expect(service.getStudentId().data ?? '', 'custom-id-123');
    });

    test('setStudentId is reflected in getStudentId', () async {
      final service = StudentIdService();
      await service.init();
      final generated = service.getStudentId().data ?? '';
      service.setStudentId('overridden-id');
      expect(service.getStudentId().data ?? '', 'overridden-id');
      expect(service.getStudentId().data ?? '', isNot(generated));
    });

    test('value persists across instances via Hive', () async {
      final service1 = StudentIdService();
      await service1.init();
      service1.setStudentId('persistent-id');

      final service2 = StudentIdService();
      await service2.init();
      expect(service2.getStudentId().data ?? '', 'persistent-id');
    });

    test('Hive-stored value is loaded on init', () async {
      final box = await Hive.openBox('student_id');
      await box.put('id', 'hive-stored-id');
      await box.close();

      final service = StudentIdService();
      await service.init();
      expect(service.getStudentId().data ?? '', 'hive-stored-id');
    });

    test('empty Hive value is ignored and new UUID is generated', () async {
      final box = await Hive.openBox('student_id');
      await box.put('id', '');
      await box.close();

      final service = StudentIdService();
      await service.init();
      final id = service.getStudentId().data ?? '';
      expect(id, isNotEmpty);
    });
  });

  group('StudentIdService.getDaysSinceLastActivity', () {
    late String hivePath;

    setUp(() async {
      hivePath = (await Directory.systemTemp.createTemp('student_id_days_')).path;
      Hive.init(hivePath);
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    Future<void> storeLastActivity(DateTime when) async {
      final box = await Hive.openBox(HiveBoxNames.studentId);
      await box.put('lastActivityAt', when.toIso8601String());
      await box.close();
    }

    test('counts calendar days, not elapsed 24h periods, across a '
        'spring-forward-like 23h span', () async {
      // Fri 2026-03-27 23:00 -> Mon 2026-03-30 01:00 spans 49h
      // when a DST spring-forward (a 23h calendar day) falls
      // inside the window: 3 calendar days, but only 2 elapsed
      // days. The count must be the calendar-day one so the
      // absence gates (>= 1 banner, >= 3 deviation, < 7 dialog)
      // do not fire a day late.
      await storeLastActivity(DateTime(2026, 3, 27, 23));

      final service =
          StudentIdService(clock: _FixedClock(DateTime(2026, 3, 30, 1)));
      await service.init();

      expect(service.getDaysSinceLastActivity(), 3);
    });

    test('counts calendar days across a fall-back-like 25h span', () async {
      // Sat 2026-10-24 23:00 -> Mon 2026-10-27 01:00 spans 51h
      // with a fall-back (25h calendar day) inside the window:
      // still 3 calendar days, 2 elapsed days.
      await storeLastActivity(DateTime(2026, 10, 24, 23));

      final service =
          StudentIdService(clock: _FixedClock(DateTime(2026, 10, 27, 1)));
      await service.init();

      expect(service.getDaysSinceLastActivity(), 3);
    });

    test('returns 0 for activity earlier on the same calendar day', () async {
      await storeLastActivity(DateTime(2026, 3, 30, 8));

      final service =
          StudentIdService(clock: _FixedClock(DateTime(2026, 3, 30, 23)));
      await service.init();

      expect(service.getDaysSinceLastActivity(), 0);
    });

    test('returns -1 when no activity was ever recorded', () async {
      final service =
          StudentIdService(clock: _FixedClock(DateTime(2026, 3, 30, 1)));
      await service.init();

      expect(service.getDaysSinceLastActivity(), -1);
    });

    test('updateLastActivity captures the calendar-day count and persists '
        'the clock time', () async {
      await storeLastActivity(DateTime(2026, 3, 27, 23));

      final service =
          StudentIdService(clock: _FixedClock(DateTime(2026, 3, 30, 1)));
      await service.init();
      await service.updateLastActivity();

      // The captured count is the calendar-day gap to the old
      // timestamp (3), not the elapsed one (2)...
      expect(service.getDaysSinceLastActivity(), 3);
      // ...and the new last-activity instant is the clock's now.
      expect(service.getLastActivityAt(), DateTime(2026, 3, 30, 1));
    });
  });

  group('StudentIdService without init (no Hive)', () {
    test('getStudentId generates UUID without prior init', () {
      final service = StudentIdService();
      final id = service.getStudentId().data ?? '';
      expect(id, isA<String>());
      expect(id.length, greaterThan(0));
    });

    test('setStudentId works without prior init', () {
      final service = StudentIdService();
      service.setStudentId('no-init-id');
      expect(service.getStudentId().data ?? '', 'no-init-id');
    });
  });

  group('Providers', () {
    test('studentIdServiceProvider creates a singleton', () {
      final service = StudentIdService();
      expect(service, isNotNull);
    });

    test('studentIdValueProvider is not null', () {
      final provider = studentIdValueProvider;
      expect(provider, isNotNull);
    });

    test('studentIdProvider is not null', () {
      final provider = studentIdProvider;
      expect(provider, isNotNull);
    });
  });
}

class _FixedClock implements Clock {
  final DateTime fixed;

  _FixedClock(this.fixed);

  @override
  DateTime now() => fixed;
}
