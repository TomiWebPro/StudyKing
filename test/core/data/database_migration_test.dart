import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/database_migration.dart';

void main() {
  group('DatabaseMigration', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(dir.path);
    });

    tearDown(() {
      Hive.deleteBoxFromDisk('db_version');
      Hive.deleteBoxFromDisk('questions');
      Hive.deleteBoxFromDisk('lessons');
      Hive.deleteBoxFromDisk('topics');
      Hive.deleteBoxFromDisk('answers');
      Hive.deleteBoxFromDisk('sources');
      Hive.deleteBoxFromDisk('attempts');
      Hive.deleteBoxFromDisk('lessonBlocks');
      Hive.deleteBoxFromDisk('sessions');
    });

    test('runMigrations completes without error', () async {
      await expectLater(DatabaseMigration.runMigrations(), completes);
    });

    test('runMigrations creates version box and sets version', () async {
      await DatabaseMigration.runMigrations();

      final box = Hive.box('db_version');
      expect(box.get('version'), 1);
    });

    test('runMigrations is idempotent', () async {
      await DatabaseMigration.runMigrations();
      await DatabaseMigration.runMigrations();

      final box = Hive.box('db_version');
      expect(box.get('version'), 1);
    });

    test('validateSchema returns valid result after migrations', () async {
      await DatabaseMigration.runMigrations();

      final result = await DatabaseMigration.validateSchema();

      expect(result.isValid, isTrue);
      expect(result.missingBoxes, isEmpty);
      expect(result.hasErrors, isFalse);
    });

    test('validateSchema handles errors gracefully', () async {
      final result = await DatabaseMigration.validateSchema();

      expect(result.isValid, isFalse);
      expect(result.hasErrors, isTrue);
    });

    test('DatabaseValidationResult defaults', () {
      final result = DatabaseValidationResult();

      expect(result.isValid, isTrue);
      expect(result.missingBoxes, []);
      expect(result.currentVersion, 0);
      expect(result.error, isNull);
      expect(result.hasErrors, isFalse);
    });

    test('DatabaseValidationResult with errors', () {
      final result = DatabaseValidationResult(
        isValid: false,
        missingBoxes: ['topics', 'questions'],
        error: 'Connection failed',
      );

      expect(result.isValid, isFalse);
      expect(result.missingBoxes, ['topics', 'questions']);
      expect(result.error, 'Connection failed');
      expect(result.hasErrors, isTrue);
    });

    test('DatabaseValidationResult with only missing boxes', () {
      final result = DatabaseValidationResult(
        missingBoxes: ['topics'],
      );

      expect(result.isValid, isTrue);
      expect(result.missingBoxes, ['topics']);
      expect(result.error, isNull);
      expect(result.hasErrors, isTrue);
    });

    test('DatabaseValidationResult with non-default version', () {
      final result = DatabaseValidationResult(
        currentVersion: 5,
      );

      expect(result.currentVersion, 5);
      expect(result.isValid, isTrue);
      expect(result.hasErrors, isFalse);
    });

    test('DatabaseValidationResult with error only', () {
      final result = DatabaseValidationResult(
        isValid: false,
        error: 'Disk full',
      );

      expect(result.isValid, isFalse);
      expect(result.missingBoxes, isEmpty);
      expect(result.error, 'Disk full');
      expect(result.hasErrors, isTrue);
    });
  });
}
