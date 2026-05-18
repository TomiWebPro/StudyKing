import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/settings/providers/settings_providers.dart';
import 'package:studyking/features/settings/services/data_backup_service.dart';

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
  });
}
