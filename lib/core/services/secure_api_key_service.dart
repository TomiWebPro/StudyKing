import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studyking/core/utils/logger.dart';

class SecureApiKeyService {
  static final Logger _logger = const Logger('SecureApiKeyService');
  static const _apiKeyKey = 'sk_api_key';
  static const _backupApiKeyKey = 'sk_backup_api_key';

  final FlutterSecureStorage _storage;

  SecureApiKeyService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveApiKey(String key) async {
    try {
      if (key.isEmpty) {
        await _storage.delete(key: _apiKeyKey);
      } else {
        await _storage.write(key: _apiKeyKey, value: key);
      }
    } on PlatformException catch (e) {
      if (e.code != 'KeyringLocked') {
        _logger.w('Failed to save API key to secure storage', e);
      }
    } catch (e) {
      _logger.w('Failed to save API key to secure storage', e);
    }
  }

  Future<String> getApiKey() async {
    try {
      final key = await _storage.read(key: _apiKeyKey);
      return key ?? '';
    } on PlatformException catch (e) {
      if (e.code != 'KeyringLocked') {
        _logger.w('Failed to read API key from secure storage', e);
      }
      return '';
    } catch (e) {
      _logger.w('Failed to read API key from secure storage', e);
      return '';
    }
  }

  Future<void> saveBackupApiKey(String key) async {
    try {
      if (key.isEmpty) {
        await _storage.delete(key: _backupApiKeyKey);
      } else {
        await _storage.write(key: _backupApiKeyKey, value: key);
      }
    } on PlatformException catch (e) {
      if (e.code != 'KeyringLocked') {
        _logger.w('Failed to save backup API key to secure storage', e);
      }
    } catch (e) {
      _logger.w('Failed to save backup API key to secure storage', e);
    }
  }

  Future<String> getBackupApiKey() async {
    try {
      final key = await _storage.read(key: _backupApiKeyKey);
      return key ?? '';
    } on PlatformException catch (e) {
      if (e.code != 'KeyringLocked') {
        _logger.w('Failed to read backup API key from secure storage', e);
      }
      return '';
    } catch (e) {
      _logger.w('Failed to read backup API key from secure storage', e);
      return '';
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _apiKeyKey);
      await _storage.delete(key: _backupApiKeyKey);
    } on PlatformException catch (e) {
      if (e.code != 'KeyringLocked') {
        _logger.w('Failed to clear secure storage', e);
      }
    } catch (e) {
      _logger.w('Failed to clear secure storage', e);
    }
  }

  Future<void> migrateFromHive(String hiveKey, String hiveBackupKey) async {
    final existing = await getApiKey();
    if (existing.isEmpty && hiveKey.isNotEmpty) {
      await saveApiKey(hiveKey);
      _logger.i('Migrated API key from Hive to secure storage');
    }
    final existingBackup = await getBackupApiKey();
    if (existingBackup.isEmpty && hiveBackupKey.isNotEmpty) {
      await saveBackupApiKey(hiveBackupKey);
      _logger.i('Migrated backup API key from Hive to secure storage');
    }
  }
}
