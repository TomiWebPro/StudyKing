import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/data_backup_service.dart';

void main() {
  group('DataBackupService', () {
    test('can be instantiated', () {
      final service = DataBackupService();
      expect(service, isA<DataBackupService>());
    });

    test('methods have correct signatures', () async {
      final service = DataBackupService();
      expect(service.exportAllData, isA<Function>());
      expect(service.exportSingleBox, isA<Function>());
    });
  });
}
