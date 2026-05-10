import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageConfig {
  const StorageConfig._();

  static const String databaseName = 'studyking_v1.db';
  static const String hiveBoxName = 'studyking_storage_v1';
  static const String tempDirectoryName = 'temp';
  static const String cacheDirectoryName = 'cache';
  static const String studyMaterialsDirectoryName = 'StudyKing';

  static Future<String> appStoragePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, studyMaterialsDirectoryName);
  }

  static Future<String> tempDirectoryPath() async {
    final dir = await getTemporaryDirectory();
    return p.join(dir.path, tempDirectoryName);
  }

  static Future<String> cacheDirectoryPath() async {
    final dir = await getApplicationCacheDirectory();
    return p.join(dir.path, cacheDirectoryName);
  }
}
