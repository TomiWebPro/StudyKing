import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/services/data_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
  });

  group('DataBackupService', () {
    late DataBackupService service;

    setUp(() {
      service = DataBackupService();
    });

    group('exportAllData', () {
      test('exports data to a file successfully', () async {
        final boxData = {
          'attempts': [
            {'id': 'a1', 'score': 85},
            {'id': 'a2', 'score': 92},
          ],
          'notes': [
            {'title': 'Note 1', 'content': 'Hello'},
          ],
        };

        final result = await service.exportAllData(boxData: boxData);

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<String>());
        expect((result.data as String).endsWith('.json'), isTrue);
      });

      test('exported file contains valid JSON with all data', () async {
        final boxData = {
          'sessions': [
            {'id': 's1', 'duration': 3600},
          ],
        };

        final result = await service.exportAllData(boxData: boxData);
        final filePath = result.data!;
        final file = File(filePath);
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        final decoded = jsonDecode(content) as Map<String, dynamic>;

        expect(decoded['version'], equals(1));
        expect(decoded['exportedAt'], isA<String>());
        expect(decoded['boxes'], isA<Map>());
        final boxes = decoded['boxes'] as Map;
        expect(boxes['sessions'], isA<List>());
      });

      test('accepts custom filename', () async {
        final result = await service.exportAllData(
          boxData: {},
          filename: 'my_custom_backup',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, contains('my_custom_backup'));
      });

      test('exports empty box data', () async {
        final result = await service.exportAllData(boxData: {});

        expect(result.isSuccess, isTrue);
        final filePath = result.data!;
        final file = File(filePath);
        final content = await file.readAsString();
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final boxes = decoded['boxes'] as Map;
        expect(boxes, isEmpty);
      });

      test('exports multiple boxes', () async {
        final boxData = {
          'box1': [{'k': 'v1'}],
          'box2': [{'k': 'v2'}],
          'box3': [{'k': 'v3'}],
        };

        final result = await service.exportAllData(boxData: boxData);
        expect(result.isSuccess, isTrue);

        final content = await File(result.data!).readAsString();
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final boxes = decoded['boxes'] as Map;
        expect(boxes.length, equals(3));
      });

      test('export with persistent outputDir succeeds', () async {
        final result = await service.exportAllData(
          boxData: {'test': [{'k': 'v'}]},
          outputDir: 'persistent',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<String>());
      });

      test('export with custom filename includes the name', () async {
        final result = await service.exportAllData(
          boxData: {'test': [{'k': 'v'}]},
          filename: 'custom_name',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, contains('custom_name'));
      });
    });

    group('exportSingleBox', () {
      test('exports single box data', () async {
        final records = [
          {'id': 'r1', 'value': 10},
          {'id': 'r2', 'value': 20},
        ];

        final result = await service.exportSingleBox(
          boxName: 'practice',
          records: records,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, contains('practice_backup'));
      });

      test('exported single box file contains valid structure', () async {
        final result = await service.exportSingleBox(
          boxName: 'testBox',
          records: [{'data': 'test'}],
        );

        final content = await File(result.data!).readAsString();
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final boxes = decoded['boxes'] as Map;
        expect(boxes.containsKey('testBox'), isTrue);
        final boxData = boxes['testBox'] as List;
        expect(boxData.length, equals(1));
      });
    });

    group('restoreData', () {
      test('restores data from a valid backup file', () async {
        final exportResult = await service.exportAllData(boxData: {
          'attempts': [
            {'id': 'a1', 'score': 85},
            {'id': 'a2', 'score': 92},
          ],
        });

        final restoreResult = await service.restoreData(exportResult.data!);

        expect(restoreResult.isSuccess, isTrue);
        expect(restoreResult.data, isA<Map>());
        expect(restoreResult.data!.containsKey('attempts'), isTrue);
        expect(restoreResult.data!['attempts']!.length, equals(2));
      });

      test('restores data with correct field types', () async {
        final now = DateTime.now().toIso8601String();
        final exportResult = await service.exportAllData(boxData: {
          'metrics': [
            {'name': 'accuracy', 'value': 0.85, 'timestamp': now},
          ],
        });

        final restoreResult = await service.restoreData(exportResult.data!);

        expect(restoreResult.isSuccess, isTrue);
        final metrics = restoreResult.data!['metrics']!;
        expect(metrics[0]['name'], equals('accuracy'));
        expect(metrics[0]['value'], equals(0.85));
        expect(metrics[0]['timestamp'], equals(now));
      });

      test('returns failure for non-existent file', () async {
        final result = await service.restoreData('/nonexistent/path.json');

        expect(result.isFailure, isTrue);
      });

      test('returns failure for invalid JSON file', () async {
        final tempDir = Directory.systemTemp.createTempSync('backup_test_');
        final badFile = File('${tempDir.path}/bad.json');
        await badFile.writeAsString('not json at all');

        final result = await service.restoreData(badFile.path);

        expect(result.isFailure, isTrue);
      });

      test('returns failure for missing version field', () async {
        final tempDir = Directory.systemTemp.createTempSync('backup_test_');
        final badFile = File('${tempDir.path}/no_version.json');
        await badFile.writeAsString(jsonEncode({
          'exportedAt': DateTime.now().toIso8601String(),
          'boxes': {},
        }));

        final result = await service.restoreData(badFile.path);

        expect(result.isFailure, isTrue);
      });

      test('returns failure for missing exportedAt field', () async {
        final tempDir = Directory.systemTemp.createTempSync('backup_test_');
        final badFile = File('${tempDir.path}/no_exported.json');
        await badFile.writeAsString(jsonEncode({
          'version': 1,
          'boxes': {},
        }));

        final result = await service.restoreData(badFile.path);

        expect(result.isFailure, isTrue);
      });

      test('returns failure for missing boxes field', () async {
        final tempDir = Directory.systemTemp.createTempSync('backup_test_');
        final badFile = File('${tempDir.path}/no_boxes.json');
        await badFile.writeAsString(jsonEncode({
          'version': 1,
          'exportedAt': DateTime.now().toIso8601String(),
        }));

        final result = await service.restoreData(badFile.path);

        expect(result.isFailure, isTrue);
      });

      test('re-imported data matches exported data', () async {
        final originalData = {
          'questions': [
            {'q': 'What?', 'a': 'Answer'},
          ],
          'progress': [
            {'topic': 'math', 'pct': 75},
          ],
        };

        final exportResult = await service.exportAllData(boxData: originalData);
        final restoreResult = await service.restoreData(exportResult.data!);

        expect(restoreResult.isSuccess, isTrue);
        expect(restoreResult.data!['questions']!, equals(originalData['questions']));
        expect(restoreResult.data!['progress']!, equals(originalData['progress']));
      });

      test('round-trip preserves data integrity', () async {
        final data = {
          'users': [
            {'id': 'u1', 'name': 'Alice', 'scores': [95, 87, 92]},
          ],
        };

        final exportResult = await service.exportAllData(boxData: data);
        final restoreResult = await service.restoreData(exportResult.data!);

        final users = restoreResult.data!['users']!;
        expect(users[0]['id'], equals('u1'));
        expect(users[0]['name'], equals('Alice'));
        expect((users[0]['scores'] as List).length, equals(3));
      });
    });
  });
}
