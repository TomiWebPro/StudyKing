import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_storage_config.dart';

void main() {
  group('StorageConfig', () {
    test('databaseName is studyking_v1.db', () {
      expect(StorageConfig.databaseName, 'studyking_v1.db');
    });

    test('hiveBoxName is studyking_storage_v1', () {
      expect(StorageConfig.hiveBoxName, 'studyking_storage_v1');
    });

    test('tempDirectoryName is temp', () {
      expect(StorageConfig.tempDirectoryName, 'temp');
    });

    test('cacheDirectoryName is cache', () {
      expect(StorageConfig.cacheDirectoryName, 'cache');
    });

    test('studyMaterialsDirectoryName is studyking', () {
      expect(StorageConfig.studyMaterialsDirectoryName, 'studyking');
    });
  });

  group('StorageConfig async path methods', () {
    const channel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
            return '/tmp/test_docs';
          case 'getTemporaryDirectory':
            return '/tmp/test_temp_dir';
          case 'getApplicationCacheDirectory':
            return '/tmp/test_cache_dir';
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('appStoragePath creates and returns studyking directory under documents',
        () async {
      final path = await StorageConfig.appStoragePath();
      expect(path, contains('/tmp/test_docs'));
      expect(path, contains('studyking'));
    });

    test('tempDirectoryPath creates and returns temp directory', () async {
      final path = await StorageConfig.tempDirectoryPath();
      expect(path, contains('/tmp/test_temp_dir'));
      expect(path, contains('temp'));
    });

    test('cacheDirectoryPath creates and returns cache directory', () async {
      final path = await StorageConfig.cacheDirectoryPath();
      expect(path, contains('/tmp/test_cache_dir'));
      expect(path, contains('cache'));
    });
  });
}
