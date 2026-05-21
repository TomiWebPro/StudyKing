import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studyking/core/services/secure_api_key_service.dart';

class InMemoryFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    return _store.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    return Map.from(_store);
  }
}

void main() {
  group('SecureApiKeyService', () {
    late InMemoryFlutterSecureStorage storage;
    late SecureApiKeyService service;

    setUp(() {
      storage = InMemoryFlutterSecureStorage();
      service = SecureApiKeyService(storage: storage);
    });

    group('saveApiKey', () {
      test('stores API key', () async {
        await service.saveApiKey('test-api-key');
        final stored = await storage.read(key: 'sk_api_key');
        expect(stored, 'test-api-key');
      });

      test('deletes API key when empty string provided', () async {
        await service.saveApiKey('test-api-key');
        await service.saveApiKey('');
        final stored = await storage.read(key: 'sk_api_key');
        expect(stored, isNull);
      });
    });

    group('getApiKey', () {
      test('returns saved API key', () async {
        await service.saveApiKey('test-api-key');
        final key = await service.getApiKey();
        expect(key, 'test-api-key');
      });

      test('returns empty string when no key saved', () async {
        final key = await service.getApiKey();
        expect(key, '');
      });
    });

    group('saveBackupApiKey', () {
      test('stores backup API key', () async {
        await service.saveBackupApiKey('backup-key');
        final stored = await storage.read(key: 'sk_backup_api_key');
        expect(stored, 'backup-key');
      });

      test('deletes backup API key when empty string provided', () async {
        await service.saveBackupApiKey('backup-key');
        await service.saveBackupApiKey('');
        final stored = await storage.read(key: 'sk_backup_api_key');
        expect(stored, isNull);
      });
    });

    group('getBackupApiKey', () {
      test('returns saved backup API key', () async {
        await service.saveBackupApiKey('backup-key');
        final key = await service.getBackupApiKey();
        expect(key, 'backup-key');
      });

      test('returns empty string when no backup key saved', () async {
        final key = await service.getBackupApiKey();
        expect(key, '');
      });
    });

    group('clearAll', () {
      test('removes both API keys', () async {
        await service.saveApiKey('key1');
        await service.saveBackupApiKey('key2');
        await service.clearAll();
        expect(await service.getApiKey(), '');
        expect(await service.getBackupApiKey(), '');
      });
    });

    group('migrateFromHive', () {
      test('migrates API key from Hive when secure storage is empty', () async {
        await service.migrateFromHive('hive-key', 'hive-backup');
        expect(await service.getApiKey(), 'hive-key');
        expect(await service.getBackupApiKey(), 'hive-backup');
      });

      test('does not overwrite existing API key', () async {
        await service.saveApiKey('existing-key');
        await service.migrateFromHive('hive-key', 'hive-backup');
        expect(await service.getApiKey(), 'existing-key');
      });

      test('does not overwrite existing backup API key', () async {
        await service.saveBackupApiKey('existing-backup');
        await service.migrateFromHive('hive-key', 'hive-backup');
        expect(await service.getBackupApiKey(), 'existing-backup');
      });

      test('handles empty Hive keys gracefully', () async {
        await service.migrateFromHive('', '');
        expect(await service.getApiKey(), '');
        expect(await service.getBackupApiKey(), '');
      });
    });
  });
}
