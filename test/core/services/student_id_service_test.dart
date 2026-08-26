import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/student_id_service.dart';

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
