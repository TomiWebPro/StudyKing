import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studyking/core/providers/secure_api_key_provider.dart';
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

class _FakeSecureApiKeyService extends SecureApiKeyService {
  final Map<String, String> _store = {};
  bool _shouldThrow = false;

  _FakeSecureApiKeyService();

  void setShouldThrow(bool value) => _shouldThrow = value;

  @override
  Future<String> getApiKey() async {
    if (_shouldThrow) throw Exception('storage error');
    return _store['sk_api_key'] ?? '';
  }

  @override
  Future<void> saveApiKey(String key) async {
    if (_shouldThrow) throw Exception('storage error');
    if (key.isEmpty) {
      _store.remove('sk_api_key');
    } else {
      _store['sk_api_key'] = key;
    }
  }

  @override
  Future<String> getBackupApiKey() async {
    if (_shouldThrow) throw Exception('storage error');
    return _store['sk_backup_api_key'] ?? '';
  }

  @override
  Future<void> clearAll() async {
    if (_shouldThrow) throw Exception('storage error');
    _store.clear();
  }
}

void main() {
  group('secureApiKeyServiceProvider', () {
    test('provides a SecureApiKeyService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(secureApiKeyServiceProvider);
      expect(service, isA<SecureApiKeyService>());
    });

    test('singleton behavior - same instance across reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(secureApiKeyServiceProvider);
      final b = container.read(secureApiKeyServiceProvider);
      expect(identical(a, b), isTrue);
    });

    test('can be overridden with fake service', () async {
      final fake = _FakeSecureApiKeyService();
      final container = ProviderContainer(overrides: [
        secureApiKeyServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final service = container.read(secureApiKeyServiceProvider);
      expect(service, same(fake));
      await service.saveApiKey('test-key');
      final key = await service.getApiKey();
      expect(key, 'test-key');
    });

    test('propagates errors when service throws', () async {
      final fake = _FakeSecureApiKeyService();
      fake.setShouldThrow(true);

      final container = ProviderContainer(overrides: [
        secureApiKeyServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final service = container.read(secureApiKeyServiceProvider);
      expect(() async => await service.getApiKey(), throwsA(isA<Exception>()));
    });

    test('can clear keys through provider', () async {
      final fake = _FakeSecureApiKeyService();
      final container = ProviderContainer(overrides: [
        secureApiKeyServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final service = container.read(secureApiKeyServiceProvider);
      await service.saveApiKey('key1');
      await service.clearAll();
      expect(await service.getApiKey(), '');
    });
  });
}
