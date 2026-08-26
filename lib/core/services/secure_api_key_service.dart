import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureApiKeyService {
  static final Logger _logger = const Logger('SecureApiKeyService');
  static const _apiKeyKey = 'sk_api_key';
  static const _backupApiKeyKey = 'sk_backup_api_key';

  final FlutterSecureStorage _storage;

  SecureApiKeyService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<Result<void>> saveApiKey(String key) async {
    return Result.capture(() async {
      if (key.isEmpty) {
        await _storage.delete(key: _apiKeyKey);
      } else {
        await _storage.write(key: _apiKeyKey, value: key);
      }
    }, context: 'saveApiKey');
  }

  Future<Result<String>> getApiKey() async {
    return Result.capture(() async {
      final key = await _storage.read(key: _apiKeyKey);
      return key ?? '';
    }, context: 'getApiKey');
  }

  Future<Result<void>> saveBackupApiKey(String key) async {
    return Result.capture(() async {
      if (key.isEmpty) {
        await _storage.delete(key: _backupApiKeyKey);
      } else {
        await _storage.write(key: _backupApiKeyKey, value: key);
      }
    }, context: 'saveBackupApiKey');
  }

  Future<Result<String>> getBackupApiKey() async {
    return Result.capture(() async {
      final key = await _storage.read(key: _backupApiKeyKey);
      return key ?? '';
    }, context: 'getBackupApiKey');
  }

  Future<Result<void>> clearAll() async {
    return Result.capture(() async {
      await _storage.delete(key: _apiKeyKey);
      await _storage.delete(key: _backupApiKeyKey);
    }, context: 'clearAll');
  }

  Future<Result<void>> migrateFromHive(String hiveKey, String hiveBackupKey) async {
    return Result.capture(() async {
      final existingResult = await getApiKey();
      final existing = existingResult.data ?? '';
      if (existing.isEmpty && hiveKey.isNotEmpty) {
        final saveResult = await saveApiKey(hiveKey);
        if (saveResult.isFailure) {
          _logger.w('Failed to migrate API key from Hive: ${saveResult.error}');
        } else {
          _logger.i('Migrated API key from Hive to secure storage');
        }
      }
      final existingBackupResult = await getBackupApiKey();
      final existingBackup = existingBackupResult.data ?? '';
      if (existingBackup.isEmpty && hiveBackupKey.isNotEmpty) {
        final saveResult = await saveBackupApiKey(hiveBackupKey);
        if (saveResult.isFailure) {
          _logger.w('Failed to migrate backup API key from Hive: ${saveResult.error}');
        } else {
          _logger.i('Migrated backup API key from Hive to secure storage');
        }
      }
    }, context: 'migrateFromHive');
  }
}
