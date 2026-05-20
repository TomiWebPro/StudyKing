import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/settings/providers/settings_providers.dart';
import 'package:studyking/features/settings/services/data_backup_service.dart';

class _FakeDataBackupService extends DataBackupService {
  @override
  Future<Result<Map<String, List<Map<String, dynamic>>>>> restoreData(
    String filePath,
  ) async {
    return Result.success({
      'sessions': [
        {'id': 's1', 'data': 'test'},
      ],
    });
  }

  @override
  Future<Result<String>> exportAllData({
    required Map<String, List<Map<String, dynamic>>> boxData,
    String? filename,
    String? outputDir,
    bool compress = true,
  }) async {
    return Result.success('/fake/backup/path.json');
  }
}

class _ThrowingDataBackupService extends DataBackupService {
  @override
  Future<Result<Map<String, List<Map<String, dynamic>>>>> restoreData(
    String filePath,
  ) async {
    return Result.failure('Backup restore failed');
  }
}

void main() {
  group('dataBackupServiceProvider', () {
    test('creates a DataBackupService instance', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(dataBackupServiceProvider), isA<DataBackupService>());
    });

    test('is singleton - same instance across reads', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final instance1 = container.read(dataBackupServiceProvider);
      final instance2 = container.read(dataBackupServiceProvider);
      expect(identical(instance1, instance2), isTrue);
    });

    test('override wiring works', () {
      final fakeService = DataBackupService();
      final container = ProviderContainer(
        overrides: [
          dataBackupServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(() => container.dispose());
      expect(container.read(dataBackupServiceProvider), same(fakeService));
    });

    test('behavioral assertion - fake restoreData flows through provider', () async {
      final fakeService = _FakeDataBackupService();
      final container = ProviderContainer(
        overrides: [
          dataBackupServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(() => container.dispose());

      final service = container.read(dataBackupServiceProvider);
      final result = await service.restoreData('/fake/path');
      expect(result.isSuccess, isTrue);
      expect(result.data, containsPair('sessions', isA<List>()));
    });

    test('error propagation - throwing fake error surfaces through provider', () async {
      final throwingService = _ThrowingDataBackupService();
      final container = ProviderContainer(
        overrides: [
          dataBackupServiceProvider.overrideWithValue(throwingService),
        ],
      );
      addTearDown(() => container.dispose());

      final service = container.read(dataBackupServiceProvider);
      final result = await service.restoreData('/bad/path');
      expect(result.isFailure, isTrue);
      expect(result.error, contains('Backup restore failed'));
    });

    test('behavioral assertion - fake exportAllData flows through provider', () async {
      final fakeService = _FakeDataBackupService();
      final container = ProviderContainer(
        overrides: [
          dataBackupServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(() => container.dispose());

      final service = container.read(dataBackupServiceProvider);
      final result = await service.exportAllData(boxData: {
        'subjects': [
          {'id': 's1', 'name': 'Math'},
        ],
      });
      expect(result.isSuccess, isTrue);
      expect(result.data, endsWith('.json'));
    });
  });
}
